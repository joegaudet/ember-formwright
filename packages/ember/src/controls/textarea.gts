import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import type { ControlSignature } from './signature.ts'

export default class Textarea extends Component<ControlSignature<string>> {
  get length() {
    return (this.args.value ?? '').length
  }

  onInput = (event: Event) => this.args.onChange((event.target as HTMLTextAreaElement).value)

  <template>
    <textarea
      id={{@id}}
      name={{@name}}
      class="fw-control fw-textarea"
      value={{@value}}
      placeholder={{@placeholder}}
      disabled={{@disabled}}
      readonly={{@readonly}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      maxlength={{@maxLength}}
      data-test-fw-control={{@type}}
      ...attributes
      {{on "input" this.onInput}}
    ></textarea>
    {{#if @showCount}}
      <span class="fw-count" aria-live="polite" data-test-fw-count>
        {{this.length}}{{#if @maxLength}} / {{@maxLength}}{{/if}}
      </span>
    {{/if}}
  </template>
}
