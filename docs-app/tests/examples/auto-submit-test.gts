import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, CheckboxHarness, RadioHarness, field } from '@formwright/test-support'
import PreferencesForm, { createModel } from 'docs-app/examples/auto-submit'

class PreferencesHarness extends FormHarness {
  static formName = 'preferences'
  @field(CheckboxHarness) declare newsletter: CheckboxHarness
  @field(RadioHarness) declare digest: RadioHarness
}

module('Example | auto-submit', function (hooks) {
  setupRenderingTest(hooks)

  test('every change saves', async function (assert) {
    const model = createModel()
    await render(<template><PreferencesForm @model={{model}} /></template>)
    const preferences = new PreferencesHarness()

    await preferences.digest.select('daily')
    assert.dom('.status').hasText('All changes saved')
    assert.false(preferences.isDirty)

    await preferences.newsletter.uncheck()
    assert.false(model.newsletter)
    await a11yAudit()
  })
})
