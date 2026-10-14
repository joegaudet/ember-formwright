import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field, form } from '@ember-formwright/test-support'
import ProductForm, { createModel } from 'docs-app/examples/nested-forms'

class WarehouseHarness extends FormHarness {
  @field(InputHarness) declare city: InputHarness
}

class ProductHarness extends FormHarness {
  static formName = 'product'
  @field(InputHarness) declare name: InputHarness
  @form(WarehouseHarness) declare warehouse: WarehouseHarness
}

module('Example | nested-forms', function (hooks) {
  setupRenderingTest(hooks)

  test('children validate with the root and save after it', async function (assert) {
    const model = createModel()
    await render(<template><ProductForm @model={{model}} /></template>)
    const product = new ProductHarness()

    await product.warehouse.city.fillIn('')
    await product.submit()
    assert.deepEqual(product.name.errors, ['Name the product'])
    assert.deepEqual(product.warehouse.city.errors, ['Where is it stocked?'])

    await product.name.fillIn('Teapot')
    await product.warehouse.city.fillIn('Antwerp')
    await product.submit()
    assert.strictEqual(model.saved, 1)
    assert.strictEqual(model.warehouse.saved, 1)
    assert.dom('.hook-log li').exists({ count: 2 })
    assert.dom('.hook-log li:last-child').hasText('warehouse saved (after its parent)')
    await a11yAudit()
  })
})
