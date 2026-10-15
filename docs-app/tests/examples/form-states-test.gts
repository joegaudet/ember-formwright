import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render, click } from '@ember/test-helpers'
import { FormHarness, InputHarness, SelectHarness, field } from '@ember-formwright/test-support'
import ShipmentForm, { createModel } from 'docs-app/examples/form-states'

class ShipmentHarness extends FormHarness {
  static formName = 'shipment'
  @field(SelectHarness) declare carrier: SelectHarness
  @field(InputHarness) declare tracking: InputHarness
}

module('Example | form-states', function (hooks) {
  setupRenderingTest(hooks)

  test('disabled and readonly reach every field', async function (assert) {
    const model = createModel()
    await render(<template><ShipmentForm @model={{model}} /></template>)
    const shipment = new ShipmentHarness()

    assert.false(shipment.tracking.isDisabled)
    await click('input[value="disabled"]')
    assert.true(shipment.tracking.isDisabled)
    assert.true(shipment.carrier.isDisabled)

    await click('input[value="readonly"]')
    assert.dom(shipment.tracking.control).hasAttribute('readonly')
    assert.true(shipment.carrier.isDisabled, 'a select has no readonly, so it disables')
    await a11yAudit()
  })
})
