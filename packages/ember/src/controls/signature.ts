/** What a field passes every control, whichever it is. */
export interface ControlWiring<V> {
  /** Put this on the focusable element: the field's <label for> points at it. */
  id: string
  /** Form-unique name, e.g. for radio groups. */
  name: string
  /** The control name the field was given (`email`, `select`, ...). */
  type: string
  /** The value at the field's path; a model can hold null or nothing there. */
  value: V | null | undefined
  /** What the control stores; the field only accepts a control whose V its path can hold. */
  onChange: (value: V) => void
  disabled?: boolean
  readonly?: boolean
  required?: boolean
  invalid?: boolean
  /** Space-separated ids of the hint and error elements. */
  describedBy?: string
  placeholder?: string
  label?: string
  /**
   * The control renders inside a callout: a popover in the top layer. A control with its own
   * floating UI (a dropdown, a date picker) should render it in place, inside the control,
   * or it opens underneath the popover and a click on it closes the callout.
   */
  callout?: boolean
}

/**
 * The contract between a Field and the control it renders: the wiring every control gets, plus
 * the args of its own (`Extra`). A field takes the control's extra args as its own, and only
 * accepts a control whose value its path can hold. Any component with this signature can be
 * passed to `@control`, or registered by name with `registerControl`.
 */
export interface ControlSignature<
  V = unknown,
  Extra extends object = object,
  E extends Element = HTMLElement,
> {
  Element: E
  Args: ControlWiring<V> & Extra
}

/** A control's own args: all but the wiring every control gets. */
export type OwnArgs<S extends { Args: object }> = Omit<S['Args'], keyof ControlWiring<unknown>>

export type OptionAccessor = string | ((option: any) => unknown)

interface OptionAccessors {
  optionKey?: OptionAccessor
  optionLabel?: OptionAccessor
}

/**
 * The args of a control that picks from `@options`, storing values of type T. The options are
 * T themselves, unless `@storeKey` stores each option's key: then they can be anything.
 */
export type OptionArgs<T = unknown> =
  | (OptionAccessors & { options?: readonly T[]; storeKey?: false })
  | (OptionAccessors & {
      options?: readonly unknown[]
      /** Store the option's key instead of the option itself. */
      storeKey: true
    })

/** What one option of a list-valued path is: `Tag` for `Tag[]`. */
export type ItemOf<T> = T extends readonly (infer E)[] ? E : never

/** Number and date bounds. */
export interface RangeArgs {
  min?: number | string
  max?: number | string
  step?: number | string
}

/** For `currency`: an ISO 4217 code (default USD) and a locale (default the browser's). */
export interface CurrencyArgs {
  currency?: string
  locale?: string
}

/** For `checkbox-group`: the most options that can be checked. */
export type MaxArgs = Pick<RangeArgs, 'max'>

/** A length cap, and whether to show a counter. */
export interface LengthArgs {
  maxLength?: number
  showCount?: boolean
}
