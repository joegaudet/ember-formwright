import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, SelectHarness, RadioHarness, field } from '@ember-formwright/test-support'
import OrderForm, { createModel, OrderState } from 'docs-app/examples/data-real-enums'

class OrderHarness extends FormHarness {
  static formName = 'order'
  @field(SelectHarness) declare state: SelectHarness
  @field(RadioHarness) declare nextState: RadioHarness
}

module('Example | data-real-enums', function (hooks) {
  setupRenderingTest(hooks)

  test('enum members as options, stored as members or raw strings', async function (assert) {
    const model = createModel()
    await render(<template><OrderForm @model={{model}} /></template>)
    const order = new OrderHarness()

    assert.deepEqual(order.state.options, ['pending', 'shipped', 'delivered', 'cancelled'])
    await order.state.select('delivered')
    assert.strictEqual(model.state, OrderState.Delivered)

    assert.deepEqual(order.nextState.options, ['shipped', 'delivered', 'cancelled'])
    await order.nextState.select('cancelled')
    assert.strictEqual(model.nextState, 'cancelled')
    await a11yAudit()
  })
})
