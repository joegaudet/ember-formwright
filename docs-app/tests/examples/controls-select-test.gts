import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, SelectHarness, field } from '@ember-formwright/test-support'
import SelectControls, { createModel } from 'docs-app/examples/controls-select'

class CheckoutHarness extends FormHarness {
  static formName = 'checkout'
  @field(SelectHarness) declare country: SelectHarness
  @field(SelectHarness) declare size: SelectHarness
  @field(SelectHarness) declare plan: SelectHarness
}

module('Example | controls-select', function (hooks) {
  setupRenderingTest(hooks)

  test('objects, primitives and stored keys', async function (assert) {
    const model = createModel()
    await render(<template><SelectControls @model={{model}} /></template>)
    const checkout = new CheckoutHarness()

    assert.strictEqual(checkout.country.value, null, 'the placeholder shows')
    await checkout.country.select('jp')
    assert.deepEqual(model.country, { code: 'jp', name: 'Japan' })

    await checkout.size.select('XL')
    assert.strictEqual(model.size, 'XL')

    assert.deepEqual(checkout.plan.options, ['hobby', 'team', 'enterprise'])
    assert.dom('[data-test-fw-option="enterprise"]').isDisabled()
    await checkout.plan.select('hobby')
    assert.strictEqual(model.plan, 'hobby')
    await a11yAudit()
  })
})
