import Component from '@glimmer/component'
import type Owner from '@ember/owner'
import { tracked } from '@glimmer/tracking'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { guidFor } from '@ember/object/internals'
import { htmlSafe } from '@ember/template'
import { modifier } from 'ember-modifier'
import type Form from './form.gts'
import { FieldLabel, FieldHint, FieldControl, FieldErrors, FieldGroup } from './field-parts.gts'
import { normalizePath, type Path, type PathValue } from '../path.ts'
import { lookupControl, isGroupControl, type ControlComponent } from '../registry.ts'
import type { OptionAccessor } from '../controls/signature.ts'
import { labelOf, matches } from '../controls/options.ts'
import {
  getDefaultLayout,
  resolveLayout,
  type FieldBlockParams,
  type FieldLayout,
  type FieldLayoutState,
} from '../layout.ts'

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
    /** Override the form's @layout for this field: a registered name or a component. */
    layout?: string | FieldLayout
  }
  Blocks: {
    /** Replaces just the control; label, hint and errors still render around it. */
    default: [FieldBlockParams<PathValue<M, P>>]
  }
}

const isEmpty = (v: unknown) =>
  v === null || v === undefined || v === '' || (Array.isArray(v) && !v.length)

export default class Field<M extends object = object, P extends Path<M> = Path<M>>
  extends Component<FieldSignature<M, P>>
  implements FieldLayoutState
{
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

  get required() {
    return Boolean(this.args.required)
  }

  /** The field's @layout, else its form's, else the default. */
  get layout(): FieldLayout {
    const layout = this.args.layout ?? this.form.layout
    return layout === undefined ? getDefaultLayout() : resolveLayout(layout)
  }

  /** The layout passes the block params on untyped; they are this field's. */
  asBlock = (params: FieldBlockParams) => params as FieldBlockParams<PathValue<M, P>>

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
      <this.layout
        @parts={{hash
          Label=(component FieldLabel field=this)
          Hint=(component FieldHint field=this)
          Control=(component FieldControl field=this hasBlock=(has-block))
          Errors=(component FieldErrors field=this)
          Group=(component FieldGroup field=this)
        }}
        @field={{this}}
        as |params|
      >{{yield (this.asBlock params)}}</this.layout>
    </div>
  </template>
}
