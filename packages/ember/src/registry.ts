import type { ComponentLike } from '@glint/template'
import type { ControlSignature } from './controls/signature.ts'
import Input from './controls/input.gts'
import Textarea from './controls/textarea.gts'
import Select from './controls/select.gts'
import Radio from './controls/radio.gts'
import Checkbox from './controls/checkbox.gts'
import CheckboxGroup from './controls/checkbox-group.gts'
import Currency from './controls/currency.gts'

export type ControlComponent = ComponentLike<ControlSignature<any>>

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

/** Makes a control available to every form as `@control="<name>"`. */
export function registerControl(
  name: string,
  component: ControlComponent,
  options: { group?: boolean } = {},
): void {
  controls.set(name, component)
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
