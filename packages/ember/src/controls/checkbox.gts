import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import type { ControlSignature } from './signature.ts'

export default class Checkbox extends Component<ControlSignature<boolean>> {
  onChange = (event: Event) => this.args.onChange((event.target as HTMLInputElement).checked)

  <template>
    <input
      type="checkbox"
      id={{@id}}
      name={{@name}}
      class="fw-control fw-checkbox"
      checked={{@value}}
      disabled={{if @readonly true @disabled}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
      {{on "change" this.onChange}}
    />
  </template>
}
