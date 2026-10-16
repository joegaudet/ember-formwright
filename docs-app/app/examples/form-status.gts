import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Form } from '@ember-formwright/ember'

export class Profile {
  @tracked name = 'Ada'
}

export const createModel = () => new Profile()

const validator = (profile: Profile) => (profile.name ? {} : { name: ['Name is required'] })

export default class ProfileForm extends Component<{ Args: { model: Profile } }> {
  @tracked failNext = false
  @tracked note = ''

  toggleFail = (event: Event) => (this.failNext = (event.target as HTMLInputElement).checked)

  // Your data layer goes here; this pretends to call an API.
  save = async () => {
    this.note = ''
    await new Promise(resolve => setTimeout(resolve, 600))
    if (this.failNext) throw new Error('The server said no')
  }

  failed = () => (this.note = 'The save failed. Your change is still here: retry or reset.')

  <template>
    <Form
      @model={{@model}}
      @name="profile"
      @validator={{validator}}
      @onSubmit={{this.save}}
      @failedSubmit={{this.failed}}
      as |f|
    >
      <f.Field @for="name" @label="Name" />

      <label class="switch">
        <input type="checkbox" data-test-fail-next {{on "change" this.toggleFail}} />
        Make the next save fail
      </label>

      <div class="actions">
        <f.Submit>Save</f.Submit>
        <f.Reset />
      </div>

      <p class="status">
        <code>f.state.status</code>
        is
        <output class="status-badge" data-status={{f.state.status}}>{{f.state.status}}</output>
      </p>
      <p class="status status-note" aria-live="polite">{{this.note}}</p>
    </Form>
  </template>
}
