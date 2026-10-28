import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form, type FieldLayoutSignature } from '@ember-formwright/ember'

/**
 * A layout of your own: the hint under the label, in a header, and the errors above the
 * control. It only places parts; each brings its own ids, aria-* and test hooks.
 */
const Stacked: TOC<FieldLayoutSignature> = <template>
  <@parts.Group>
    <@parts.Label />
    <@parts.Hint class="stacked-hint" />
    <@parts.Errors />
    <@parts.Control as |control|>{{yield control}}</@parts.Control>
  </@parts.Group>
</template>

export class Account {
  @tracked username = ''
}

export const createModel = () => new Account()

const validator = (account: Account) =>
  account.username.length >= 3 ? {} : { username: ['At least 3 characters'] }

const AccountForm: TOC<{ Args: { model: Account } }> = <template>
  <Form @model={{@model}} @name="account" @layout={{Stacked}} @validator={{validator}} as |f|>
    <f.Field @for="username" @label="Username" @hint="Shown on your profile" />
    <f.Submit>Save</f.Submit>
  </Form>
</template>

export default AccountForm
