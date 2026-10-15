import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form, type ErrorMap } from '@ember-formwright/ember'

export class Invite {
  @tracked email = ''
}

export const createModel = () => new Invite()

export default class InviteForm extends Component<{ Args: { model: Invite } }> {
  @tracked log: string[] = []

  record = (entry: string) => (this.log = [...this.log, entry])

  validator = (invite: Invite): ErrorMap =>
    invite.email.includes('@') ? {} : { email: ['Enter an email address'] }

  willSubmit = () => (this.record('willSubmit → true'), true)
  onSubmit = async (invite: Invite) => {
    this.record(`onSubmit(${invite.email})`)
    await new Promise(resolve => setTimeout(resolve, 200))
  }
  didSubmit = () => this.record('didSubmit')
  didNotSubmit = (errors: ErrorMap) =>
    this.record(`didNotSubmit(${Object.keys(errors).join(', ')})`)
  onChange = (path: string, value: unknown) =>
    this.record(`onChange(${path}, ${JSON.stringify(value)})`)

  <template>
    <Form
      @model={{@model}}
      @name="invite"
      @validator={{this.validator}}
      @willSubmit={{this.willSubmit}}
      @onSubmit={{this.onSubmit}}
      @didSubmit={{this.didSubmit}}
      @didNotSubmit={{this.didNotSubmit}}
      @onChange={{this.onChange}}
      as |f|
    >
      <f.Field @for="email" @control="email" @label="Invite by email" />
      <f.Submit>Send invite</f.Submit>
    </Form>

    <ol class="hook-log" aria-label="Hooks called">
      {{#each this.log as |entry|}}<li><code>{{entry}}</code></li>{{/each}}
    </ol>
  </template>
}
