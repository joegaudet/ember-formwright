import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, NumberHarness, CurrencyHarness, field } from '@ember-formwright/test-support'
import NumberControls, { createModel } from 'docs-app/examples/controls-numbers'

class OrderHarness extends FormHarness {
  static formName = 'order'
  @field(NumberHarness) declare quantity: NumberHarness
  @field(NumberHarness) declare volume: NumberHarness
  @field(CurrencyHarness) declare total: CurrencyHarness
}

module('Example | controls-numbers', function (hooks) {
  setupRenderingTest(hooks)

  test('numbers are stored as numbers; currency formats with Intl', async function (assert) {
    const model = createModel()
    await render(<template><NumberControls @model={{model}} /></template>)
    const order = new OrderHarness()

    await order.quantity.fillIn(5)
    assert.strictEqual(model.quantity, 5)
    assert.strictEqual(order.volume.value, 60)
    assert.strictEqual(order.total.value, '1.499,50 €')

    await order.total.fillIn('20,5')
    assert.strictEqual(model.total, 20.5)
    assert.strictEqual(order.total.value, '20,50 €')
    await a11yAudit()
  })
})
