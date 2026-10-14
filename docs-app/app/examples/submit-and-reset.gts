import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form } from '@formwright/ember'

export class Profile {
  @tracked displayName = 'Ada Lovelace'
  @tracked bio = 'Wrote the first program.'
}

export const createModel = () => new Profile()

export default class ProfileForm extends Component<{ Args: { model: Profile } }> {
  @tracked savedAt: string | null = null

  // Your data layer goes here; this pretends to call an API.
  save = async () => {
    await new Promise(resolve => setTimeout(resolve, 600))
    this.savedAt = new Date().toLocaleTimeString()
  }

  <template>
    <Form @model={{@model}} @name="profile" @onSubmit={{this.save}} as |f|>
      <f.Field @for="displayName" @label="Display name" />
      <f.Field @for="bio" @control="textarea" @label="Bio" />

      <div class="actions">
        <f.Submit>Save</f.Submit>
        <f.Reset>Discard changes</f.Reset>
      </div>

      <p class="status" aria-live="polite">
        {{#if f.state.isSubmitting}}
          Saving…
        {{else if f.state.isDirty}}
          You have unsaved changes.
        {{else if this.savedAt}}
          Saved at
          {{this.savedAt}}.
        {{/if}}
      </p>
    </Form>
  </template>
}
