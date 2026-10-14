import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render, click } from '@ember/test-helpers'
import { FormHarness, FieldHarness, field } from '@formwright/test-support'
import FeedbackForm, { createModel } from 'docs-app/examples/custom-rating'

/** A custom control gets its own harness: subclass FieldHarness. */
class RatingHarness extends FieldHarness {
  static controls = ['rating', 'custom']

  get value(): number {
    return this.element.querySelectorAll('.star.is-lit').length
  }

  async rate(stars: number): Promise<void> {
    await click(this.element.querySelector(`[data-test-fw-option="${stars}"]`)!)
  }
}

class FeedbackHarness extends FormHarness {
  static formName = 'feedback'
  @field(RatingHarness) declare quality: RatingHarness
  @field(RatingHarness) declare support: RatingHarness
}

module('Example | custom-rating', function (hooks) {
  setupRenderingTest(hooks)

  test('a registered control and a passed component', async function (assert) {
    const model = createModel()
    await render(<template><FeedbackForm @model={{model}} /></template>)
    const feedback = new FeedbackHarness()

    assert.strictEqual(feedback.quality.value, 4)
    assert.strictEqual(feedback.quality.label, 'Product quality', 'group controls get a legend')
    await feedback.support.rate(5)
    assert.strictEqual(model.support, 5)
    await a11yAudit()
  })
})
