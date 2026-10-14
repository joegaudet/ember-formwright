import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import type { ControlSignature } from './signature.ts'
import { isDisabled as isOptionDisabled, keyOf, labelOf, matches, toStored } from './options.ts'

export default class Select extends Component<ControlSignature> {
  get options() {
    return this.args.options ?? []
  }

  get hasValue() {
    return this.args.value !== null && this.args.value !== undefined && this.args.value !== ''
  }

  get selected() {
    return this.options.find(o => matches(this.args.value, o, this.args.optionKey))
  }

  /** The stored value isn't one of the options; show it rather than silently picking another. */
  get isUnknown() {
    return this.hasValue && this.selected === undefined
  }

  keyFor = (option: unknown) => String(keyOf(option, this.args.optionKey))
  labelFor = (option: unknown) => labelOf(option, this.args.optionLabel)
  isSelected = (option: unknown) => option === this.selected
  isDisabled = (option: unknown) => isOptionDisabled(option)

  onChange = (event: Event) => {
    const key = (event.target as HTMLSelectElement).value
    const option = this.options.find(o => this.keyFor(o) === key)
    this.args.onChange(
      option === undefined ? null : toStored(option, this.args.storeKey, this.args.optionKey),
    )
  }

  <template>
    <select
      id={{@id}}
      name={{@name}}
      class="fw-control fw-select"
      disabled={{if @readonly true @disabled}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
      {{on "change" this.onChange}}
    >
      {{#if this.isUnknown}}
        <option value={{this.keyFor @value}} selected disabled hidden>{{this.labelFor
            @value
          }}</option>
      {{else}}
        <option value="" selected={{if this.hasValue false true}} disabled={{@required}}>
          {{@placeholder}}
        </option>
      {{/if}}
      {{#each this.options as |choice|}}
        <option
          value={{this.keyFor choice}}
          selected={{this.isSelected choice}}
          disabled={{this.isDisabled choice}}
          data-test-fw-option={{this.keyFor choice}}
        >{{this.labelFor choice}}</option>
      {{/each}}
    </select>
  </template>
}
