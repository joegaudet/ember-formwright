import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import ReviewForm, { createModel } from 'docs-app/examples/controls-textarea'

class ReviewHarness extends FormHarness {
  static formName = 'review'
  @field(InputHarness) declare body: InputHarness
}

module('Example | controls-textarea', function (hooks) {
  setupRenderingTest(hooks)

  test('counts characters against the cap', async function (assert) {
    const model = createModel()
    await render(<template><ReviewForm @model={{model}} /></template>)
    const review = new ReviewHarness()

    await review.body.fillIn('Lovely.')
    assert.strictEqual(model.body, 'Lovely.')
    assert.dom('[data-test-fw-count]').hasText('7 / 200')
    await a11yAudit()
  })
})
