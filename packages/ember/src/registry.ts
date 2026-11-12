import type { ComponentLike } from '@glint/template'
import type {
  ControlSignature,
  CurrencyArgs,
  ItemOf,
  MaxArgs,
  LengthArgs,
  OptionArgs,
  RangeArgs,
} from './controls/signature.ts'
import Input from './controls/input.gts'
import Textarea from './controls/textarea.gts'
import Select from './controls/select.gts'
import Radio from './controls/radio.gts'
import Checkbox from './controls/checkbox.gts'
import CheckboxGroup from './controls/checkbox-group.gts'
import Currency from './controls/currency.gts'

type TextSignature = ControlSignature<string, LengthArgs>
type DateSignature = ControlSignature<string, RangeArgs>

/**
 * Formwright's controls by name, each typed for a field whose path holds `T`. A choice control
 * stores what its options are (or their keys), so its signature follows `T`.
 */
export interface FormwrightBuiltinControls<T> {
  input: TextSignature
  text: TextSignature
  email: TextSignature
  password: TextSignature
  search: TextSignature
  tel: TextSignature
  url: TextSignature
  color: TextSignature
  date: DateSignature
  datetime: DateSignature
  time: DateSignature
  /** Emptying it stores null. */
  number: ControlSignature<number | null, RangeArgs>
  range: ControlSignature<number, RangeArgs>
  textarea: ControlSignature<string, LengthArgs>
  /** Picking the blank option stores null. */
  select: ControlSignature<NonNullable<T> | null, OptionArgs<NonNullable<T>>>
  radio: ControlSignature<NonNullable<T>, OptionArgs<NonNullable<T>>>
  checkbox: ControlSignature<boolean>
  'checkbox-group': ControlSignature<ItemOf<T>[], OptionArgs<ItemOf<T>> & MaxArgs>
  currency: ControlSignature<number | null, CurrencyArgs>
}

declare const declared: unique symbol

/**
 * The controls an app or add-on registers, by name: add yours with declaration merging,
 * alongside `registerControl`. A name here replaces the built-in of that name.
 *
 *   declare module '@ember-formwright/ember' {
 *     interface FormwrightControls {
 *       stars: ControlSignature<number | null, { max?: number }>
 *     }
 *   }
 */
export interface FormwrightControls {
  /** Not a control: keeps this interface from being empty until controls are added to it. */
  readonly [declared]?: never
}

/**
 * Like `FormwrightControls`, for controls whose value follows the field's path (`T`), as a
 * select's is whatever its options are:
 *
 *   declare module '@ember-formwright/ember' {
 *     interface FormwrightChoiceControls<T> {
 *       combobox: ControlSignature<NonNullable<T> | null, OptionArgs<NonNullable<T>>>
 *     }
 *   }
 */
export interface FormwrightChoiceControls<T> {
  /** Not a control: carries `T` for the declarations that add to this interface. */
  readonly [declared]?: T
}

/** Every control name, with its signature for a path holding `T`; later ones replace earlier. */
export type Controls<T> = Omit<
  FormwrightBuiltinControls<T>,
  keyof FormwrightControls | keyof FormwrightChoiceControls<T>
> &
  Omit<FormwrightControls, keyof FormwrightChoiceControls<T>> &
  FormwrightChoiceControls<T>

export type ControlName = keyof Controls<unknown> & string

export type ControlValue<S> = S extends { Args: { onChange: (value: infer V) => void } } ? V : never

/** What a control storing `V` can show: a list it stores, read-only too. */
type Shows<V> = V extends (infer E)[] ? V | readonly E[] : V

/**
 * A control fits a path holding `T` when the path can hold anything it stores, and it can show
 * anything the path holds. Loosely typed paths (`unknown`, `any`) take any control.
 */
type Fits<V, T> = unknown extends T
  ? true
  : [V] extends [never]
    ? false
    : [V] extends [T]
      ? [NonNullable<T>] extends [Shows<V>]
        ? true
        : false
      : false

/** The control names a field whose path holds `T` can use. */
export type ControlsFor<T> = {
  [K in keyof Controls<T>]: Fits<ControlValue<Controls<T>[K]>, T> extends true ? K : never
}[keyof Controls<T>] &
  string

export type ControlComponent = ComponentLike<ControlSignature<any, any>>

const controls = new Map<string, ControlComponent>([
  ['input', Input],
  ['text', Input],
  ['email', Input],
  ['password', Input],
  ['search', Input],
  ['tel', Input],
  ['url', Input],
  ['color', Input],
  ['date', Input],
  ['datetime', Input],
  ['time', Input],
  ['range', Input],
  ['number', Input],
  ['textarea', Textarea],
  ['select', Select],
  ['radio', Radio],
  ['checkbox', Checkbox],
  ['checkbox-group', CheckboxGroup],
  ['currency', Currency],
])

/** Controls made of several inputs; their field renders a <fieldset> and <legend>. */
const groups = new Set(['radio', 'checkbox-group'])

/**
 * Makes a control available to every form as `@control="<name>"`. A name declared in
 * `FormwrightControls` (or a built-in's) must get a component with that signature.
 */
export function registerControl<N extends string>(
  name: N,
  component: N extends ControlName ? ComponentLike<Controls<unknown>[N]> : ControlComponent,
  options: { group?: boolean } = {},
): void {
  controls.set(name, component as ControlComponent)
  if (options.group) groups.add(name)
  else groups.delete(name)
}

export function isGroupControl(name: string): boolean {
  return groups.has(name)
}

export function lookupControl(name: string): ControlComponent {
  const control = controls.get(name)
  if (!control) {
    throw new Error(
      `Unknown Formwright control "${name}". Pass a component to @control, or register it with registerControl('${name}', Component). Known controls: ${[...controls.keys()].join(', ')}`,
    )
  }
  return control
}
