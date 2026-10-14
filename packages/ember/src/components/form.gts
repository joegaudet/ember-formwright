import Component from '@glimmer/component'
import type Owner from '@ember/owner'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { waitForPromise } from '@ember/test-waiters'
import { modifier } from 'ember-modifier'
import type { ComponentLike, WithBoundArgs } from '@glint/template'
import { getDefaultAdapter, type ModelAdapter } from '../adapter.ts'
import { runValidator, hasErrors, type ErrorMap, type Validator } from '../validation.ts'
import Field from './field.gts'
import Button from './button.gts'
import Errors from './errors.gts'

/** What `<Form as |f|>` exposes as `f.state`. */
export interface FormState<M extends object = object> {
  readonly model: M
  readonly isDirty: boolean
  readonly isSubmitting: boolean
  readonly isValid: boolean
  readonly errors: ErrorMap
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
    adapter?: ModelAdapter<M>
    validator?: Validator<M>
    /** Persists the model. Default: the adapter's save (POJOs: `model.save()` if present). */
    onSubmit?: (model: M) => unknown
    /** Return false (or a promise of false) to cancel a valid submit, e.g. after a confirm. */
    willSubmit?: (model: M) => boolean | Promise<boolean>
    didSubmit?: (model: M) => void
    /** Called when saving throws. Without it the error is rethrown. */
    failedSubmit?: (error: unknown) => void
    /** Called when validation stops a submit. */
    didNotSubmit?: (errors: ErrorMap) => void
    willReset?: (model: M) => boolean | Promise<boolean>
    didReset?: (model: M) => void
    /** Called after each value is written to the model. */
    onChange?: (path: string, value: unknown, model: M) => void
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
        Field: WithBoundArgs<typeof Field, 'form'>
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

/** `f.Form`: a Form bound to its parent. */
export type NestedForm = ComponentLike<{
  Element: HTMLFormElement | HTMLFieldSetElement
  Args: Omit<FormSignature<any>['Args'], 'parent'>
  Blocks: FormSignature<any>['Blocks']
}>

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
  @tracked errors: ErrorMap = {}
  @tracked isSubmitting = false
  /** After a failed submit, every change revalidates so errors clear as they're fixed. */
  @tracked hasFailedSubmit = false
  /**
   * Not tracked: fields and nested forms register while the form renders, and writing
   * tracked state there trips Ember's backtracking assertion. `version` is bumped instead:
   * right after a render that registered something, on removal, and on save.
   */
  fields: Field[] = []
  children: Form<any>[] = []
  @tracked version = 0
  /** The values fields started with (or were last saved with), by path. */
  baseline = new Map<string, unknown>()
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

  get formErrors(): string[] {
    return this.errorsFor('')
  }

  // ---- fields --------------------------------------------------------------------------

  read(path: string): unknown {
    return this.adapter.get(this.model, path)
  }

  errorsFor(path: string): string[] {
    return [...(this.errors[path] ?? []), ...(this.adapter.errorsFor?.(this.model, path) ?? [])]
  }

  isFieldDirty(path: string): boolean {
    void this.version
    return this.baseline.has(path) && !same(this.baseline.get(path), this.read(path))
  }

  register(field: Field): void {
    if (!this.baseline.has(field.path))
      this.baseline.set(field.path, snapshotOf(this.read(field.path)))
    this.fields.push(field)
    this.invalidateSoon()
  }

  unregister(field: Field): void {
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
  commit(path: string, value: unknown): void {
    this.adapter.set(this.model, path, value)
    this.args.onChange?.(path, value, this.model)
    if (this.root.hasFailedSubmit) void waitForPromise(this.root.validate())
    if (this.args.autoSubmit) void this.submit()
  }

  // ---- validation ----------------------------------------------------------------------

  async validate(): Promise<boolean> {
    const [errors] = await Promise.all([
      runValidator(this.args.validator, this.model),
      ...this.children.map(c => c.validate()),
    ])
    if (!this.isDestroying) this.errors = errors
    return this.isValid
  }

  async focusFirstInvalid(): Promise<void> {
    // Errors render on the next frame; then the invalid controls carry aria-invalid.
    await new Promise(resolve => requestAnimationFrame(resolve))
    this.element?.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus()
  }

  // ---- submit / reset ------------------------------------------------------------------

  submit = (): Promise<void> => waitForPromise(this.root.submitTree())

  reset = (): Promise<void> => waitForPromise(this.resetTree())

  async submitTree(): Promise<void> {
    if (this.isSubmitting) return
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
    await (this.args.onSubmit ? this.args.onSubmit(this.model) : this.adapter.save?.(this.model))
    this.args.didSubmit?.(this.model)
  }

  markSaved(): void {
    for (const field of this.fields)
      this.baseline.set(field.path, snapshotOf(this.read(field.path)))
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
      for (const [path, value] of this.baseline) {
        if (!same(value, this.read(path))) this.adapter.set(this.model, path, snapshotOf(value))
      }
    }
    for (const field of this.fields) field.discard()
    this.errors = {}
    this.hasFailedSubmit = false
    this.children.forEach(c => c.rollback())
  }

  willDestroy(): void {
    super.willDestroy()
    if ((this.args.resetOnDestroy ?? true) && this.isDirty) this.rollback()
    this.args.parent?.disown(this)
  }

  // ---- template ------------------------------------------------------------------------

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
            Field=(component Field form=this)
            Form=(component Form parent=this)
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
            Field=(component Field form=this)
            Form=(component Form parent=this)
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
