import Component from '@glimmer/component'
import type Owner from '@ember/owner'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { guidFor } from '@ember/object/internals'
import { htmlSafe } from '@ember/template'
import { modifier } from 'ember-modifier'
import type { ComponentLike } from '@glint/template'
import type Form from './form.gts'
import Errors from './errors.gts'
import { normalizePath, type Path, type PathValue } from '../path.ts'
import { lookupControl, isGroupControl, type ControlComponent } from '../registry.ts'
import type { ControlSignature, OptionAccessor } from '../controls/signature.ts'
import { labelOf, matches } from '../controls/options.ts'

/**
 * The control yielded by a field's block, with the field's wiring already bound. Its extra
 * args depend on which control the field uses (`@maxLength`, `@currency`, `@mask`, ...),
 * so they're typed loosely.
 */
type BoundControl = ComponentLike<{
  Element: HTMLElement
  Args: Partial<ControlSignature['Args']> & Record<string, unknown>
}>

export interface FieldSignature<M extends object = object, P extends Path<M> = Path<M>> {
  Element: HTMLDivElement
  Args: {
    /** Set by `f.Field`; don't pass it yourself. */
    form: Form<M>
    /** The model path this field edits, e.g. "email" or "address.city"; checked against the form's model. */
    for: P
    label?: string
    hint?: string
    /** A built-in or registered control name (default "input"), or a component. */
    control?: string | ControlComponent
    placeholder?: string
    required?: boolean
    disabled?: boolean
    readonly?: boolean
    /** Override the form's @requireConfirm for this field. */
    requireConfirm?: boolean
    options?: readonly unknown[]
    optionKey?: OptionAccessor
    optionLabel?: OptionAccessor
    storeKey?: boolean
    /** Number/date bounds, or the most options a checkbox group may select. */
    min?: number | string
    max?: number | string
    step?: number | string
    /** For `textarea` (and inputs): a length cap, and whether to show a counter. */
    maxLength?: number
    showCount?: boolean
    /** For `currency`: an ISO 4217 code (default USD) and a locale (default the browser's). */
    currency?: string
    locale?: string
    /** Formats the value when shown (inline editing). */
    format?: (value: PathValue<M, P>) => string
  }
  Blocks: {
    /** Replaces just the control; label, hint and errors still render around it. */
    default: [
      {
        Control: BoundControl
        id: string
        value: PathValue<M, P>
        errors: string[]
        isInvalid: boolean
      },
    ]
  }
}

const isEmpty = (v: unknown) =>
  v === null || v === undefined || v === '' || (Array.isArray(v) && !v.length)

export default class Field<
  M extends object = object,
  P extends Path<M> = Path<M>,
> extends Component<FieldSignature<M, P>> {
  /** A value the user chose but hasn't committed yet (confirm or inline mode). */
  @tracked buffer: { value: PathValue<M, P> } | null = null
  @tracked isEditing = false
  /** Read once: a field's path is its identity in the form's baseline. */
  readonly path: P

  constructor(owner: Owner, args: FieldSignature<M, P>['Args']) {
    super(owner, args)
    // Normalizing only rewrites `items[0]` as `items.0`, which addresses the same value.
    this.path = normalizePath(args.for) as P
    args.form.register(this)
  }

  willDestroy(): void {
    super.willDestroy()
    this.args.form.unregister(this)
  }

  get form() {
    return this.args.form
  }

  get id() {
    return `fw-${guidFor(this)}`
  }

  get hintId() {
    return `${this.id}-hint`
  }

  get errorsId() {
    return `${this.id}-errors`
  }

  get fullPath() {
    return `${this.form.path}.${this.path}`
  }

  get controlName() {
    const control = this.args.control ?? 'input'
    return typeof control === 'string' ? control : 'custom'
  }

  get control(): ControlComponent {
    const control = this.args.control ?? 'input'
    return typeof control === 'string' ? lookupControl(control) : control
  }

  get isGroup() {
    return isGroupControl(this.controlName)
  }

  get value(): PathValue<M, P> {
    return this.form.read(this.path)
  }

  get controlValue(): PathValue<M, P> {
    return this.buffer ? this.buffer.value : this.value
  }

  get errors() {
    return this.form.errorsFor(this.path)
  }

  get isInvalid() {
    return this.errors.length > 0
  }

  get isDirty() {
    return this.buffer !== null || this.form.isFieldDirty(this.path)
  }

  get disabled() {
    return this.args.disabled ?? this.form.disabled
  }

  get readonly() {
    return this.args.readonly ?? this.form.readonly
  }

  get describedBy() {
    const ids = [this.args.hint && this.hintId, this.isInvalid && this.errorsId].filter(Boolean)
    return ids.length ? ids.join(' ') : undefined
  }

  get requiresConfirm() {
    return this.form.inline || (this.args.requireConfirm ?? this.form.requireConfirm)
  }

  get showControl() {
    return !this.form.inline || this.isEditing || this.isInvalid
  }

  /** In a callout the value stays visible: it's what the popover is anchored to. */
  get showDisplay() {
    return this.form.inline && (!this.isEditing || this.form.callout)
  }

  get showConfirm() {
    return this.buffer !== null || (this.form.inline && this.isEditing)
  }

  get useCallout() {
    return this.form.inline && this.form.callout && this.isEditing
  }

  get displayValue(): string {
    const value = this.value
    if (this.args.format) return this.args.format(value)
    if (isEmpty(value)) return ''
    const options = this.args.options
    const labelFor = (v: unknown) => {
      const option = options?.find(o => matches(v, o, this.args.optionKey))
      // Without the option (e.g. options from an async search), an object value is its own option.
      if (option === undefined && (typeof v !== 'object' || v === null)) return String(v)
      return labelOf(option ?? v, this.args.optionLabel)
    }
    return Array.isArray(value) ? value.map(labelFor).join(', ') : labelFor(value)
  }

  get anchorStyle() {
    return htmlSafe(`anchor-name: --${this.id}`)
  }

  get calloutStyle() {
    return htmlSafe(`position-anchor: --${this.id}`)
  }

  // ---- actions -------------------------------------------------------------------------

  /** Controls aren't typed against values, so what they send is taken as the path's type. */
  onChange = (sent: unknown) => {
    const value = sent as PathValue<M, P>
    if (this.requiresConfirm) this.buffer = { value }
    else this.form.commit(this.path, value)
  }

  commit = () => {
    if (this.buffer) this.form.commit(this.path, this.buffer.value)
    this.buffer = null
    this.isEditing = false
  }

  cancel = () => {
    this.discard()
  }

  /** Drops an uncommitted value; the form calls this on reset. */
  discard(): void {
    this.buffer = null
    this.isEditing = false
  }

  edit = () => {
    this.isEditing = true
  }

  onCalloutToggle = (event: Event) => {
    if ((event as ToggleEvent).newState === 'closed' && this.isEditing) this.cancel()
  }

  onKeydown = (event: KeyboardEvent) => {
    if (!this.requiresConfirm) return
    if (event.key === 'Escape') this.cancel()
    if (event.key === 'Enter' && this.buffer && !(event.target instanceof HTMLTextAreaElement)) {
      event.preventDefault()
      this.commit()
    }
  }

  /** Focuses the element the label points at (any control), else the first native input. */
  focusControl = modifier((element: HTMLElement, [shouldFocus]: [boolean]) => {
    if (!shouldFocus) return
    const target =
      element.querySelector<HTMLElement>(`#${CSS.escape(this.id)}`) ??
      element.querySelector<HTMLElement>('input, select, textarea')
    target?.focus()
  })

  openPopover = modifier((popover: HTMLElement, [isCallout]: [boolean]) => {
    if (!isCallout) return
    popover.showPopover()
    // shortcut: browsers without CSS anchor positioning get a one-off fixed position under
    // the value; it won't follow scrolling. Drop once anchor positioning is baseline.
    if (!CSS.supports('anchor-name', '--fw')) {
      const anchor = document
        .querySelector(`[data-fw-anchor="${this.id}"]`)
        ?.getBoundingClientRect()
      if (anchor)
        Object.assign(popover.style, { top: `${anchor.bottom}px`, left: `${anchor.left}px` })
    }
  })

  <template>
    <div
      class="fw-field fw-field--{{this.controlName}}"
      data-test-fw-field={{this.path}}
      data-test-fw-path={{this.fullPath}}
      data-test-fw-type={{this.controlName}}
      data-dirty={{if this.isDirty ""}}
      data-invalid={{if this.isInvalid ""}}
      data-disabled={{if this.disabled ""}}
      data-required={{if @required ""}}
      ...attributes
      {{on "keydown" this.onKeydown}}
    >
      {{#if this.isGroup}}
        <fieldset class="fw-group" aria-describedby={{this.describedBy}}>
          {{#if @label}}
            <legend class="fw-label" data-test-fw-label>
              {{@label}}{{#if @required}}<span
                  class="fw-required"
                  aria-hidden="true"
                >*</span>{{/if}}
            </legend>
          {{/if}}
          <ControlArea @field={{this}} @hasBlock={{has-block}} as |api|>{{yield api}}</ControlArea>
        </fieldset>
      {{else}}
        {{#if @label}}
          <label class="fw-label" for={{this.id}} data-test-fw-label>
            {{@label}}{{#if @required}}<span class="fw-required" aria-hidden="true">*</span>{{/if}}
          </label>
        {{/if}}
        <ControlArea @field={{this}} @hasBlock={{has-block}} as |api|>{{yield api}}</ControlArea>
      {{/if}}
    </div>
  </template>
}

interface ControlAreaSignature<M extends object, P extends Path<M>> {
  Args: { field: Field<M, P>; hasBlock: boolean }
  Blocks: { default: FieldSignature<M, P>['Blocks']['default'] }
}

/** Hint, inline value, control (optionally in a popover), confirm buttons and errors. */
class ControlArea<M extends object, P extends Path<M>> extends Component<
  ControlAreaSignature<M, P>
> {
  <template>
    {{#let @field as |field|}}
      {{#if field.args.hint}}
        <p id={{field.hintId}} class="fw-hint" data-test-fw-hint>{{field.args.hint}}</p>
      {{/if}}

      {{#if field.showDisplay}}
        <button
          type="button"
          class="fw-display"
          style={{field.anchorStyle}}
          disabled={{field.disabled}}
          aria-expanded={{if field.isEditing "true" "false"}}
          data-fw-anchor={{field.id}}
          data-test-fw-display
          {{on "click" field.edit}}
        >
          {{#if field.displayValue}}
            {{field.displayValue}}
          {{else}}
            <span class="fw-placeholder">{{field.args.placeholder}}</span>
          {{/if}}
        </button>
      {{/if}}

      {{#if field.showControl}}
        <div
          class="fw-control-area{{if field.useCallout ' fw-callout'}}"
          popover={{if field.useCallout "auto"}}
          style={{if field.useCallout field.calloutStyle}}
          {{field.openPopover field.useCallout}}
          {{field.focusControl field.isEditing}}
          {{on "toggle" field.onCalloutToggle}}
        >
          {{#let
            (component
              field.control
              id=field.id
              name=field.fullPath
              type=field.controlName
              value=field.controlValue
              onChange=field.onChange
              disabled=field.disabled
              readonly=field.readonly
              required=field.args.required
              invalid=field.isInvalid
              describedBy=(if field.isGroup undefined field.describedBy)
              placeholder=field.args.placeholder
              label=field.args.label
              options=field.args.options
              optionKey=field.args.optionKey
              optionLabel=field.args.optionLabel
              storeKey=field.args.storeKey
              min=field.args.min
              max=field.args.max
              step=field.args.step
              maxLength=field.args.maxLength
              showCount=field.args.showCount
              currency=field.args.currency
              locale=field.args.locale
              callout=field.useCallout
            )
            as |Control|
          }}
            {{#if @hasBlock}}
              {{yield
                (hash
                  Control=Control
                  id=field.id
                  value=field.controlValue
                  errors=field.errors
                  isInvalid=field.isInvalid
                )
              }}
            {{else}}
              <Control />
            {{/if}}
          {{/let}}

          {{#if field.showConfirm}}
            <span class="fw-confirm">
              <button
                type="button"
                class="fw-commit"
                aria-label="Apply"
                data-test-fw-commit
                {{on "click" field.commit}}
              >✔</button>
              <button
                type="button"
                class="fw-cancel"
                aria-label="Cancel"
                data-test-fw-cancel
                {{on "click" field.cancel}}
              >✘</button>
            </span>
          {{/if}}
        </div>
      {{/if}}

      <Errors @id={{field.errorsId}} @errors={{field.errors}} />
    {{/let}}
  </template>
}
