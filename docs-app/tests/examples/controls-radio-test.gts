import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, RadioHarness, field } from '@ember-formwright/test-support'
import DeliveryForm, { createModel } from 'docs-app/examples/controls-radio'

class DeliveryHarness extends FormHarness {
  static formName = 'delivery'
  @field(RadioHarness) declare speed: RadioHarness
}

module('Example | controls-radio', function (hooks) {
  setupRenderingTest(hooks)

  test('a fieldset of radios with a legend', async function (assert) {
    const model = createModel()
    await render(<template><DeliveryForm @model={{model}} /></template>)
    const delivery = new DeliveryHarness()

    assert.strictEqual(delivery.speed.label, 'Delivery speed')
    assert.dom('[data-test-fw-field="speed"] fieldset legend').exists()
    await delivery.speed.select('express')
    assert.strictEqual(model.speed, 'express')
    await a11yAudit()
  })
})
