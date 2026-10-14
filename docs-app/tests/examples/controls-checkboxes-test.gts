import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, CheckboxHarness, CheckboxGroupHarness, field } from '@formwright/test-support'
import PizzaForm, { createModel } from 'docs-app/examples/controls-checkboxes'

class PizzaHarness extends FormHarness {
  static formName = 'pizza'
  @field(CheckboxHarness) declare extraCheese: CheckboxHarness
  @field(CheckboxGroupHarness) declare toppings: CheckboxGroupHarness
}

module('Example | controls-checkboxes', function (hooks) {
  setupRenderingTest(hooks)

  test('a boolean and a capped multi-select', async function (assert) {
    const model = createModel()
    await render(<template><PizzaForm @model={{model}} /></template>)
    const pizza = new PizzaHarness()

    await pizza.extraCheese.check()
    assert.true(model.extraCheese)

    await pizza.toppings.select(['basil', 'olives', 'chili'])
    assert.deepEqual(model.toppings, ['basil', 'olives', 'chili'])
    assert.dom('[data-test-fw-option="anchovies"]').isDisabled('the fourth is disabled at the cap')
    await a11yAudit()
  })
})
