import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { changesetAdapter, changesetValidator } from '@ember-formwright/changeset'
import { Changeset, type EmberChangeset } from 'ember-changeset'
import { lookupValidator } from 'validated-changeset'

export class Account {
  @tracked username = 'ada'
  @tracked email = 'ada@example.com'

  // Your data layer goes here (a WarpDrive record already has save()).
  async save() {
    await new Promise(resolve => setTimeout(resolve, 300))
  }
}

// A validation map: each validator returns true, or the message. A map (rather than one
// function) lets validate() check every field, including ones nobody has touched.
const AccountValidations = {
  username: (_key: string, value: unknown) => Boolean(value) || 'Pick a username',
  email: (_key: string, value: unknown) => String(value).includes('@') || 'Enter an email address',
}

/** ember-changeset types `data` as `object`; this one wraps an Account. */
export type AccountChangeset = EmberChangeset & { data: Account }

export const createModel = () =>
  Changeset(
    new Account(),
    lookupValidator(AccountValidations),
    AccountValidations,
  ) as AccountChangeset

const AccountForm: TOC<{ Args: { model: AccountChangeset } }> = <template>
  <Form
    @model={{@model}}
    @name="account"
    @adapter={{changesetAdapter}}
    @validator={{changesetValidator}}
    as |f|
  >
    <f.Field @for="username" @label="Username" />
    <f.Field @for="email" @label="Email" />

    <div class="actions">
      <f.Submit>Save</f.Submit>
      <f.Reset>Discard changes</f.Reset>
    </div>

    <p class="status">Saved username: <strong>{{@model.data.username}}</strong></p>
  </Form>
</template>

export default AccountForm
