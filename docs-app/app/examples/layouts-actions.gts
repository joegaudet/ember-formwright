import { tracked } from '@glimmer/tracking'
import Component from '@glimmer/component'
import { Form } from '@ember-formwright/ember'
import { Actions } from '@ember-formwright/layouts'

export class Doc {
  @tracked title = 'Quarterly report'
  @tracked deleted = false
}

export const createModel = () => new Doc()

export default class DocForm extends Component<{ Args: { model: Doc } }> {
  delete = () => {
    this.args.model.deleted = true
  }

  <template>
    <Form @model={{@model}} @name="doc" as |f|>
      <f.Field @for="title" @label="Title" />
      <Actions>
        <:left>
          <f.Submit>Save</f.Submit>
          <f.Reset>Cancel</f.Reset>
        </:left>
        <:right>
          <f.Button @onClick={{this.delete}}>Delete</f.Button>
        </:right>
      </Actions>
      {{#if @model.deleted}}<p role="status">Deleted.</p>{{/if}}
    </Form>
  </template>
}
