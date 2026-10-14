import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, NumberHarness, field } from '@formwright/test-support'
import ListingForm, { createModel } from 'docs-app/examples/field-anatomy'

class ListingHarness extends FormHarness {
  @field(InputHarness) declare title: InputHarness
  @field(NumberHarness) declare price: NumberHarness
}

module('Example | field-anatomy', function (hooks) {
  setupRenderingTest(hooks)

  test('labels, hints, required and formatted values', async function (assert) {
    const model = createModel()
    await render(<template><ListingForm @model={{model}} /></template>)
    const listing = new ListingHarness('listing')
    const inline = new ListingHarness('listing-inline')

    assert.strictEqual(listing.title.label, 'Title')
    assert.strictEqual(listing.title.hint, 'Shown in search results.')
    assert.true(listing.title.isRequired)
    assert.strictEqual(inline.price.displayText, '$1,250')

    await listing.price.fillIn(1400)
    assert.strictEqual(model.price, 1400)
    assert.strictEqual(inline.price.displayText, '$1,400')
    await a11yAudit()
  })
})
