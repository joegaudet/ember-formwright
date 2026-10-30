import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'

export class Account {
  @tracked username = 'ada'
  @tracked email = 'ada@example.com'
}

export const createModel = () => new Account()

const AccountForm: TOC<{ Args: { model: Account } }> = <template>
  <Form @model={{@model}} @name="account" @requireConfirm={{true}} as |f|>
    <f.Field
      @for="username"
      @label="Username"
      @hint="Press Enter or ✓ to apply, Esc or ✕ to cancel."
    />
    <f.Field @for="email" @control="email" @label="Email" />
  </Form>
</template>

export default AccountForm
