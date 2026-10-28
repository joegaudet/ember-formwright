import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, CheckboxHarness, field } from '@ember-formwright/test-support'
import SettingsForm, { createModel } from 'docs-app/examples/layouts-checkbox-after'

class SettingsHarness extends FormHarness {
  static formName = 'settings'
  @field(CheckboxHarness) declare digest: CheckboxHarness
  @field(CheckboxHarness) declare mentions: CheckboxHarness
}

module('Example | layouts-checkbox-after', function (hooks) {
  setupRenderingTest(hooks)

  test('each checkbox comes before its label', async function (assert) {
    const model = createModel()
    await render(<template><SettingsForm @model={{model}} /></template>)
    const settings = new SettingsHarness()

    assert.dom('[data-test-fw-field="mentions"] > .fw-control-area + label').exists()
    assert.strictEqual(settings.mentions.label, "Email me when I'm mentioned")
    await settings.mentions.check()
    await settings.digest.uncheck()
    assert.true(model.mentions)
    assert.false(model.digest)
    await a11yAudit()
  })
})
