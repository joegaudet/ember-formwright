/**
 * The contract between a Field and the control it renders. Any component with this
 * signature can be passed to `@control`, or registered by name with `registerControl`.
 */
export interface ControlSignature<V = unknown> {
  Element: HTMLElement
  Args: {
    /** Put this on the focusable element: the field's <label for> points at it. */
    id: string
    /** Form-unique name, e.g. for radio groups. */
    name: string
    /** The control name the field was given (`email`, `select`, ...). */
    type: string
    value: V | undefined
    onChange: (value: V) => void
    disabled?: boolean
    readonly?: boolean
    required?: boolean
    invalid?: boolean
    /** Space-separated ids of the hint and error elements. */
    describedBy?: string
    placeholder?: string
    label?: string
    options?: readonly unknown[]
    optionKey?: OptionAccessor
    optionLabel?: OptionAccessor
    /** Store the option's key instead of the option itself. */
    storeKey?: boolean
    min?: number | string
    max?: number | string
    step?: number | string
    maxLength?: number
    showCount?: boolean
    currency?: string
    locale?: string
    /**
     * The control renders inside a callout: a popover in the top layer. A control with its own
     * floating UI (a dropdown, a date picker) should render it in place, inside the control,
     * or it opens underneath the popover and a click on it closes the callout.
     */
    callout?: boolean
  }
}

export type OptionAccessor = string | ((option: any) => unknown)
