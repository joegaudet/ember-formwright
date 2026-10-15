import Component from '@glimmer/component'
import type Owner from '@ember/owner'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { waitForPromise } from '@ember/test-waiters'
import { modifier } from 'ember-modifier'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { getDefaultAdapter, type ModelAdapter } from '../adapter.ts'
import {
  runValidator,
  hasErrors,
  noErrors,
  type AnyErrorMap,
  type ErrorMap,
  type Validator,
} from '../validation.ts'
import type { Path, PathValue } from '../path.ts'
import Field, { type FieldSignature } from './field.gts'
import Button from './button.gts'
import Errors from './errors.gts'

/** What `<Form as |f|>` exposes as `f.state`. */
export interface FormState<M extends object = object> {
  readonly model: M
  readonly isDirty: boolean
  readonly isSubmitting: boolean
  readonly isValid: boolean
  readonly errors: ErrorMap<M>
  submit(): Promise<void>
  reset(): Promise<void>
  validate(): Promise<boolean>
}

export interface FormSignature<M extends object = object> {
  Element: HTMLFormElement | HTMLFieldSetElement
  Args: {
    model: M
    /** Names the form for selectors and harnesses: data-test-fw-form="<name>". Default "form". */
    name?: string
    /** Typed against @model; M is inferred from @model alone. */
    adapter?: ModelAdapter<NoInfer<M>>
    validator?: Validator<M>
    /** Persists the model. Default: the adapter's save (POJOs: `model.save()` if present). */
    onSubmit?: (model: M) => unknown
    /** Return false (or a promise of false) to cancel a valid submit, e.g. after a confirm. */
    willSubmit?: (model: M) => boolean | Promise<boolean>
    didSubmit?: (model: M) => void
    /** Called when saving throws. Without it the error is rethrown. */
    failedSubmit?: (error: unknown) => void
    /** Called when validation stops a submit. */
    didNotSubmit?: (errors: ErrorMap<M>) => void
    willReset?: (model: M) => boolean | Promise<boolean>
    didReset?: (model: M) => void
    /** Called after each value is written to the model. */
    onChange?: <P extends Path<M>>(path: P, value: PathValue<M, P>, model: M) => void
    disabled?: boolean
    readonly?: boolean
    /** Fields show their value and switch to the control when clicked. */
    inline?: boolean
    /** With @inline: edit in a popover anchored to the value. */
    callout?: boolean
    /** Changes wait for an explicit commit (✔) or cancel (✘). */
    requireConfirm?: boolean
    /** Submit after every committed change. */
    autoSubmit?: boolean
    /** Roll back unsaved changes when the form is torn down. Default true. */
    resetOnDestroy?: boolean
    /** Nested forms only: the fieldset's legend. */
    legend?: string
    /** Set by `f.Form`; don't pass it yourself. */
    parent?: Form<any>
  }
  Blocks: {
    default: [
      {
        Field: BoundField<M>
        Form: NestedForm
        Submit: WithBoundArgs<typeof Button, 'kind' | 'busy' | 'text'>
        Reset: WithBoundArgs<typeof Button, 'kind' | 'onClick' | 'text'>
        Button: typeof Button
        Errors: WithBoundArgs<typeof Errors, 'errors'>
        state: FormState<M>
      },
    ]
  }
}

/**
 * `f.Form`: a Form bound to its parent. Generic like Form itself, so each nested form infers
 * its own model from `@model` and its fields are checked against it. A part of a loosely typed
 * model (a changeset's `cs.address` is `unknown`) gets a loosely typed form.
 */
export type NestedForm = abstract new <N>(...args: any) => InstanceType<
  ComponentLike<{
    Element: FormSignature<ObjectOr<N>>['Element']
    Args: Omit<FormSignature<ObjectOr<N>>['Args'], 'parent' | 'model'> & { model: N }
    Blocks: FormSignature<ObjectOr<N>>['Blocks']
  }>
>

type ObjectOr<N> = [N] extends [object] ? N : object

/**
 * `f.Field`: a Field bound to its form. Generic over the path, so each field's value,
 * `@format` and block `value` take the type at its `@for`.
 */
export type BoundField<M extends object> = abstract new <P extends Path<M>>(
  ...args: any
) => InstanceType<
  ComponentLike<{
    Element: FieldSignature<M, P>['Element']
    Args: Omit<FieldSignature<M, P>['Args'], 'form'>
    Blocks: FieldSignature<M, P>['Blocks']
  }>
>

/**
 * `{{component}}` drops a component's type parameters, so the bound nested form is restated
 * as the generic `NestedForm` it is at runtime.
 */
const asNestedForm = (form: unknown) => form as NestedForm

function same(a: unknown, b: unknown): boolean {
  if (Array.isArray(a) && Array.isArray(b)) {
    return a.length === b.length && a.every((v, i) => same(v, b[i]))
  }
  return Object.is(a, b)
}

/** Arrays are copied so in-place mutation still reads as a change. */
function snapshotOf(value: unknown) {
  return Array.isArray(value) ? [...value] : value
}

export default class Form<M extends object = object>
  extends Component<FormSignature<M>>
  implements FormState<M>
{
  @tracked errors: ErrorMap<M> = noErrors()
  @tracked isSubmitting = false
  /** After a failed submit, every change revalidates so errors clear as they're fixed. */
  @tracked hasFailedSubmit = false
  /**
   * Not tracked: fields and nested forms register while the form renders, and writing
   * tracked state there trips Ember's backtracking assertion. `version` is bumped instead:
   * right after a render that registered something, on removal, and on save.
   */
  fields: Field<M, any>[] = []
  children: Form<any>[] = []
  @tracked version = 0
  /**
   * The values fields started with (or were last saved with), by path, per model: when the
   * same form is reused for another `@model`, it gets its own baseline instead of the old one.
   */
  baselines = new WeakMap<object, Map<string, unknown>>()
  /** The submit in progress; a second submit joins it instead of saving twice. */
  inFlight: Promise<void> | null = null
  /** An auto-submit arrived while saving: save again once the current save finishes. */
  resubmit = false
  validationRun = 0
  element?: HTMLElement

  constructor(owner: Owner, args: FormSignature<M>['Args']) {
    super(owner, args)
    args.parent?.adopt(this)
  }

  get model(): M {
    return this.args.model
  }

  get name(): string {
    return this.args.name ?? 'form'
  }

  /** Dotted path from the root form, used in data-test-fw-path. */
  get path(): string {
    return this.args.parent ? `${this.args.parent.path}.${this.name}` : this.name
  }

  get root(): Form<any> {
    return this.args.parent ? this.args.parent.root : this
  }

  get adapter(): ModelAdapter<M> {
    return (this.args.adapter ??
      this.args.parent?.adapter ??
      getDefaultAdapter()) as ModelAdapter<M>
  }

  get disabled(): boolean {
    return Boolean(this.args.disabled || this.args.parent?.disabled)
  }

  get readonly(): boolean {
    return Boolean(this.args.readonly || this.args.parent?.readonly)
  }

  get inline(): boolean {
    return Boolean(this.args.inline ?? this.args.parent?.inline)
  }

  get callout(): boolean {
    return Boolean(this.args.callout ?? this.args.parent?.callout)
  }

  get requireConfirm(): boolean {
    return Boolean(this.args.requireConfirm ?? this.args.parent?.requireConfirm)
  }

  get isDirty(): boolean {
    void this.version
    return this.fields.some(f => this.isFieldDirty(f.path)) || this.children.some(c => c.isDirty)
  }

  get isValid(): boolean {
    void this.version
    return !hasErrors(this.errors) && this.children.every(c => c.isValid)
  }

  /** Not a getter: it creates the map on first use. */
  baselineOf(): Map<string, unknown> {
    let baseline = this.baselines.get(this.model)
    if (!baseline) this.baselines.set(this.model, (baseline = new Map()))
    return baseline
  }

  /** Form-level errors, plus any error no field of this form can show, so none is silent. */
  get formErrors(): string[] {
    void this.version
    const shown = new Set(this.fields.map(f => f.path))
    const orphans = Object.entries(this.errors as AnyErrorMap)
      .filter(([path]) => path !== '' && !shown.has(path))
      .flatMap(([, messages]) => messages ?? [])
    return [...this.errorsFor(''), ...orphans]
  }

  // ---- fields --------------------------------------------------------------------------

  /** The value at a path, typed by the model. */
  read<P extends Path<M>>(path: P): PathValue<M, P> {
    // Adapters read any string path; the path's type is what the model says is there.
    return this.readAt(path) as PathValue<M, P>
  }

  /** Untyped read, for paths the form tracks internally (baselines). */
  readAt(path: string): unknown {
    return this.adapter.get(this.model, path)
  }

  /** `''` for form-level errors. */
  errorsFor(path: Path<M> | ''): string[] {
    const own = (this.errors as AnyErrorMap)[path] ?? []
    return [...own, ...(this.adapter.errorsFor?.(this.model, path) ?? [])]
  }

  isFieldDirty(path: string): boolean {
    void this.version
    const baseline = this.baselineOf()
    if (!baseline.has(path)) {
      // First read for this model (e.g. @model just changed): what it holds now is clean.
      baseline.set(path, snapshotOf(this.readAt(path)))
      return false
    }
    return !same(baseline.get(path), this.readAt(path))
  }

  register(field: Field<M, any>): void {
    if (!this.baselineOf().has(field.path))
      this.baselineOf().set(field.path, snapshotOf(this.readAt(field.path)))
    this.fields.push(field)
    this.invalidateSoon()
  }

  unregister(field: Field<M, any>): void {
    this.fields = this.fields.filter(f => f !== field)
    this.version++
  }

  adopt(child: Form<any>): void {
    this.children.push(child)
    this.invalidateSoon()
  }

  pendingInvalidation = false

  /** Re-runs anything that read the field list before this render registered more fields. */
  invalidateSoon(): void {
    if (this.pendingInvalidation) return
    this.pendingInvalidation = true
    void waitForPromise(
      Promise.resolve().then(() => {
        this.pendingInvalidation = false
        if (!this.isDestroying) this.version++
      }),
    )
  }

  disown(child: Form<any>): void {
    this.children = this.children.filter(c => c !== child)
    this.version++
  }

  /** Writes a value to the model: the one way every control changes data. */
  commit<P extends Path<M>>(path: P, value: PathValue<M, P>): void {
    this.adapter.set(this.model, path, value)
    this.args.onChange?.(path, value, this.model)
    if (this.root.hasFailedSubmit) void waitForPromise(this.root.validate())
    if (this.args.autoSubmit) void this.root.submitTree(true)
  }

  // ---- validation ----------------------------------------------------------------------

  async validate(): Promise<boolean> {
    const run = ++this.validationRun
    const [errors, ...children] = await Promise.all([
      runValidator(this.args.validator, this.model),
      ...this.children.map(c => c.validate()),
    ])
    // An older, slower validation finishing last must not overwrite a newer result.
    if (run === this.validationRun && !this.isDestroying) this.errors = errors
    return !hasErrors(errors) && children.every(Boolean)
  }

  async focusFirstInvalid(): Promise<void> {
    // Errors render on the next frame; then the invalid controls carry aria-invalid.
    await new Promise(resolve => requestAnimationFrame(resolve))
    this.element?.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus()
  }

  // ---- submit / reset ------------------------------------------------------------------

  submit = (): Promise<void> => this.root.submitTree(false)

  reset = (): Promise<void> => waitForPromise(this.resetTree())

  submitTree(queue: boolean): Promise<void> {
    if (this.inFlight) {
      if (queue) this.resubmit = true
      return this.inFlight
    }
    // Registered with the test waiters once, here; callers share the same promise.
    this.inFlight = waitForPromise(
      this.runSubmit().finally(() => {
        this.inFlight = null
        if (this.resubmit && !this.isDestroying) {
          this.resubmit = false
          return this.submitTree(false)
        }
      }),
    )
    return this.inFlight
  }

  async runSubmit(): Promise<void> {
    const model = this.model

    if (!(await this.validate())) {
      this.hasFailedSubmit = true
      this.args.didNotSubmit?.(this.errors)
      await this.focusFirstInvalid()
      return
    }
    if (this.args.willSubmit && !(await this.args.willSubmit(model))) return

    this.isSubmitting = true
    try {
      await this.save()
      // Breadth-first: a child saves after its parent, so it can rely on the parent's id.
      let level = this.children
      while (level.length) {
        await Promise.all(level.filter(c => c.needsSave).map(c => c.save()))
        level = level.flatMap(c => c.children)
      }
      this.markSaved()
    } catch (error) {
      if (!this.args.failedSubmit) throw error
      this.args.failedSubmit(error)
    } finally {
      if (!this.isDestroying) this.isSubmitting = false
    }
  }

  get needsSave(): boolean {
    return this.isDirty || Boolean(this.adapter.needsSave?.(this.model))
  }

  async save(): Promise<void> {
    try {
      await (this.args.onSubmit ? this.args.onSubmit(this.model) : this.adapter.save?.(this.model))
    } catch (error) {
      // A nested form hears about its own failure; the root still stops and reports it.
      if (this.args.parent) this.args.failedSubmit?.(error)
      throw error
    }
    this.args.didSubmit?.(this.model)
  }

  markSaved(): void {
    // Every path seen, not just rendered fields: a hidden field's saved value is clean too.
    const baseline = this.baselineOf()
    for (const path of baseline.keys()) baseline.set(path, snapshotOf(this.readAt(path)))
    this.version++ // the baseline isn't tracked
    this.hasFailedSubmit = false
    this.children.forEach(c => c.markSaved())
  }

  async resetTree(): Promise<void> {
    if (this.args.willReset && !(await this.args.willReset(this.model))) return
    this.rollback()
    this.args.didReset?.(this.model)
  }

  rollback(): void {
    if (this.adapter.rollback) {
      this.adapter.rollback(this.model)
    } else {
      for (const [path, value] of this.baselineOf()) {
        if (!same(value, this.readAt(path))) this.adapter.set(this.model, path, snapshotOf(value))
      }
    }
    for (const field of this.fields) field.discard()
    this.errors = noErrors()
    this.hasFailedSubmit = false
    this.children.forEach(c => c.rollback())
  }

  willDestroy(): void {
    super.willDestroy()
    if ((this.args.resetOnDestroy ?? true) && this.isDirty) this.rollback()
    this.args.parent?.disown(this)
  }

  // ---- template ------------------------------------------------------------------------

  /** Restates the bound Field as generic over its path; `{{component}}` drops that. */
  bindField = (field: unknown) => field as BoundField<M>

  capture = modifier((element: HTMLElement) => {
    this.element = element
  })

  onSubmit = (event: SubmitEvent) => {
    event.preventDefault()
    // Without @failedSubmit a save error rejects here, so it surfaces instead of vanishing.
    void this.submit()
  }

  <template>
    {{#if @parent}}
      <fieldset
        class="fw-form fw-form--nested"
        disabled={{this.disabled}}
        data-test-fw-form={{this.name}}
        ...attributes
        {{this.capture}}
      >
        {{#if @legend}}<legend class="fw-legend">{{@legend}}</legend>{{/if}}
        {{yield
          (hash
            Field=(this.bindField (component Field form=this))
            Form=(asNestedForm (component Form parent=this))
            Submit=(component Button kind="submit" busy=this.root.isSubmitting text="Submit")
            Reset=(component Button kind="reset" onClick=this.reset text="Reset")
            Button=Button
            Errors=(component Errors errors=this.formErrors)
            state=this
          )
        }}
      </fieldset>
    {{else}}
      <form
        class="fw-form"
        novalidate
        data-test-fw-form={{this.name}}
        data-submitting={{if this.isSubmitting ""}}
        data-dirty={{if this.isDirty ""}}
        ...attributes
        {{this.capture}}
        {{on "submit" this.onSubmit}}
      >
        {{yield
          (hash
            Field=(this.bindField (component Field form=this))
            Form=(asNestedForm (component Form parent=this))
            Submit=(component Button kind="submit" busy=this.isSubmitting text="Submit")
            Reset=(component Button kind="reset" onClick=this.reset text="Reset")
            Button=Button
            Errors=(component Errors errors=this.formErrors)
            state=this
          )
        }}
      </form>
    {{/if}}
  </template>
}
