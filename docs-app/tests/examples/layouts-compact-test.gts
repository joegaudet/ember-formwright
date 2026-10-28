import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, SelectHarness, field } from '@ember-formwright/test-support'
import FilterBar, { createModel } from 'docs-app/examples/layouts-compact'

class FiltersHarness extends FormHarness {
  static formName = 'filters'
  @field(InputHarness) declare query: InputHarness
  @field(SelectHarness, 'status') declare statusFilter: SelectHarness
}

module('Example | layouts-compact', function (hooks) {
  setupRenderingTest(hooks)

  test('a dense filter bar', async function (assert) {
    const model = createModel()
    await render(<template><FilterBar @model={{model}} /></template>)
    const filters = new FiltersHarness()

    await filters.query.fillIn('invoice')
    await filters.statusFilter.select('Any')
    assert.strictEqual(model.query, 'invoice')
    assert.strictEqual(model.status, 'Any')
    await a11yAudit()
  })
})
