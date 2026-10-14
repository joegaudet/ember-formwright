import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import type { ControlSignature } from './signature.ts'
import { isDisabled, keyOf, labelOf, matches, toStored } from './options.ts'

export default class Radio extends Component<ControlSignature> {
  get options() {
    return this.args.options ?? []
  }

  /** The first radio takes the field id, so focusing the field lands on the group. */
  idFor = (index: number) => (index === 0 ? this.args.id : `${this.args.id}-${index}`)
  keyFor = (option: unknown) => String(keyOf(option, this.args.optionKey))
  labelFor = (option: unknown) => labelOf(option, this.args.optionLabel)
  isChecked = (option: unknown) => matches(this.args.value, option, this.args.optionKey)
  isDisabled = (option: unknown) => this.args.disabled || isDisabled(option)

  choose = (option: unknown) =>
    this.args.onChange(toStored(option, this.args.storeKey, this.args.optionKey))

  <template>
    <div class="fw-control fw-options fw-radio" data-test-fw-control={{@type}} ...attributes>
      {{#each this.options as |option index|}}
        <span class="fw-option">
          <input
            type="radio"
            id={{this.idFor index}}
            name={{@id}}
            value={{this.keyFor option}}
            checked={{this.isChecked option}}
            disabled={{this.isDisabled option}}
            required={{@required}}
            aria-invalid={{if @invalid "true"}}
            data-test-fw-option={{this.keyFor option}}
            {{on "change" (fn this.choose option)}}
          />
          <label for={{this.idFor index}}>{{this.labelFor option}}</label>
        </span>
      {{/each}}
    </div>
  </template>
}
