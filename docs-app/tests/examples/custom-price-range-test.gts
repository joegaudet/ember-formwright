import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render, fillIn } from '@ember/test-helpers'
import { FormHarness, FieldHarness, field } from '@formwright/test-support'
import SearchForm, { createModel } from 'docs-app/examples/custom-price-range'

class PriceRangeHarness extends FieldHarness {
  get value() {
    const read = (selector: string) =>
      Number(this.element.querySelector<HTMLInputElement>(selector)!.value)
    return { min: read('[data-test-range-min]'), max: read('[data-test-range-max]') }
  }

  async setRange(min: number, max: number): Promise<void> {
    await fillIn(this.element.querySelector('[data-test-range-min]')!, String(min))
    await fillIn(this.element.querySelector('[data-test-range-max]')!, String(max))
  }
}

class SearchHarness extends FormHarness {
  static formName = 'search'
  @field(PriceRangeHarness) declare price: PriceRangeHarness
}

module('Example | custom-price-range', function (hooks) {
  setupRenderingTest(hooks)

  test('one field edits an object', async function (assert) {
    const model = createModel()
    await render(<template><SearchForm @model={{model}} /></template>)
    const search = new SearchHarness()

    assert.deepEqual(search.price.value, { min: 100, max: 400 })
    await search.price.setRange(150, 300)
    assert.deepEqual(model.price, { min: 150, max: 300 })
    await a11yAudit()
  })
})
