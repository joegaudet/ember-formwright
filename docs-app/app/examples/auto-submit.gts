import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form } from '@ember-formwright/ember'

export class Preferences {
  @tracked newsletter = true
  @tracked digest = 'weekly'
}

export const createModel = () => new Preferences()

const DIGESTS = [
  { id: 'daily', label: 'Daily' },
  { id: 'weekly', label: 'Weekly' },
  { id: 'never', label: 'Never' },
]

export default class PreferencesForm extends Component<{ Args: { model: Preferences } }> {
  @tracked saves = 0

  save = async () => {
    await new Promise(resolve => setTimeout(resolve, 300))
    this.saves++
  }

  <template>
    <Form @model={{@model}} @name="preferences" @autoSubmit={{true}} @onSubmit={{this.save}} as |f|>
      <f.Field @for="newsletter" @control="checkbox" @label="Send me the newsletter" />
      <f.Field
        @for="digest"
        @control="radio"
        @label="Activity digest"
        @options={{DIGESTS}}
        @storeKey={{true}}
      />
      <p class="status" aria-live="polite">
        {{if f.state.isSubmitting "Saving…" (if this.saves "All changes saved")}}
      </p>
    </Form>
  </template>
}
