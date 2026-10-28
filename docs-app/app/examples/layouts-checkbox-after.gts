import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerLayouts } from '@ember-formwright/layouts'

registerLayouts()

export class Settings {
  @tracked digest = true
  @tracked mentions = false
}

export const createModel = () => new Settings()

// The layout is per field: only the checkboxes put their label after the control.
const SettingsForm: TOC<{ Args: { model: Settings } }> = <template>
  <Form @model={{@model}} @name="settings" as |f|>
    <f.Field
      @for="digest"
      @control="checkbox"
      @label="Send me a weekly digest"
      @layout="checkbox-after"
    />
    <f.Field
      @for="mentions"
      @control="checkbox"
      @label="Email me when I'm mentioned"
      @hint="At most once an hour"
      @layout="checkbox-after"
    />
  </Form>
</template>

export default SettingsForm
