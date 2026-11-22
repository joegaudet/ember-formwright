import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form, DefaultLayout, type FieldLayoutSignature } from '@ember-formwright/ember'

export class Account {
  @tracked username = 'ada'
}

export const createModel = () => new Account()

/** The default layout, with the field's status beside it. */
const WithStatus: TOC<FieldLayoutSignature> = <template>
  <DefaultLayout @parts={{@parts}} @field={{@field}} as |control|>{{yield control}}</DefaultLayout>
  <p class="status">
    <code>@field.status</code>
    is
    <output
      class="status-badge"
      data-status={{@field.status.value}}
    >{{@field.status.value}}</output>
    {{#if @field.status.isPending}}
      · press Enter or ✓ to apply it
    {{/if}}
  </p>
</template>

const AccountForm: TOC<{ Args: { model: Account } }> = <template>
  <Form @model={{@model}} @name="account" @requireConfirm={{true}} @layout={{WithStatus}} as |f|>
    <f.Field @for="username" @label="Username" />
  </Form>
</template>

export default AccountForm
