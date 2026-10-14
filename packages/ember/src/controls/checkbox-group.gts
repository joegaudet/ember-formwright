import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import type { ControlSignature } from './signature.ts'
import { isDisabled, keyOf, labelOf, matches, toStored } from './options.ts'

export default class CheckboxGroup extends Component<ControlSignature<unknown[]>> {
  get options() {
    return this.args.options ?? []
  }

  get value() {
    return this.args.value ?? []
  }

  get atMax() {
    return this.args.max !== undefined && this.value.length >= Number(this.args.max)
  }

  idFor = (index: number) => (index === 0 ? this.args.id : `${this.args.id}-${index}`)
  keyFor = (option: unknown) => String(keyOf(option, this.args.optionKey))
  labelFor = (option: unknown) => labelOf(option, this.args.optionLabel)
  isChecked = (option: unknown) => this.value.some(v => matches(v, option, this.args.optionKey))
  isDisabled = (option: unknown) =>
    this.args.disabled || isDisabled(option) || (this.atMax && !this.isChecked(option))

  toggle = (option: unknown) => {
    const next = this.isChecked(option)
      ? this.value.filter(v => !matches(v, option, this.args.optionKey))
      : [...this.value, toStored(option, this.args.storeKey, this.args.optionKey)]
    this.args.onChange(next)
  }

  <template>
    <div
      class="fw-control fw-options fw-checkbox-group"
      data-test-fw-control={{@type}}
      ...attributes
    >
      {{#each this.options as |option index|}}
        <span class="fw-option">
          <input
            type="checkbox"
            id={{this.idFor index}}
            name={{@id}}
            value={{this.keyFor option}}
            checked={{this.isChecked option}}
            disabled={{this.isDisabled option}}
            data-test-fw-option={{this.keyFor option}}
            {{on "change" (fn this.toggle option)}}
          />
          <label for={{this.idFor index}}>{{this.labelFor option}}</label>
        </span>
      {{/each}}
    </div>
  </template>
}
