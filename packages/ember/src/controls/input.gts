import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import type { ControlSignature } from './signature.ts'

const NATIVE_TYPES: Record<string, string> = { input: 'text', datetime: 'datetime-local' }
const NUMERIC = new Set(['number', 'range'])

export default class Input extends Component<ControlSignature<string | number | null>> {
  get inputType() {
    return NATIVE_TYPES[this.args.type] ?? this.args.type
  }

  get displayValue() {
    return this.args.value ?? ''
  }

  onInput = (event: Event) => {
    const raw = (event.target as HTMLInputElement).value
    if (NUMERIC.has(this.args.type)) {
      this.args.onChange(raw === '' ? null : Number(raw))
    } else {
      this.args.onChange(raw)
    }
  }

  <template>
    <input
      id={{@id}}
      name={{@name}}
      class="fw-control fw-input"
      type={{this.inputType}}
      value={{this.displayValue}}
      placeholder={{@placeholder}}
      disabled={{@disabled}}
      readonly={{@readonly}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      maxlength={{@maxLength}}
      min={{@min}}
      max={{@max}}
      step={{@step}}
      data-test-fw-control={{@type}}
      ...attributes
      {{on "input" this.onInput}}
    />
  </template>
}
