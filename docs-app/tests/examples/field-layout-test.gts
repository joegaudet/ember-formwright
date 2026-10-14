import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@formwright/test-support'
import TweetForm, { createModel } from 'docs-app/examples/field-layout'

class TweetHarness extends FormHarness {
  static formName = 'tweet'
  @field(InputHarness) declare text: InputHarness
}

module('Example | field-layout', function (hooks) {
  setupRenderingTest(hooks)

  test('the yielded Control takes control-specific arguments', async function (assert) {
    const model = createModel()
    await render(<template><TweetForm @model={{model}} /></template>)
    const tweet = new TweetHarness()

    await tweet.text.fillIn('Hello')
    assert.strictEqual(model.text, 'Hello')
    assert.dom('[data-test-fw-count]').hasText('5 / 280')
    assert.dom(tweet.text.control).hasAttribute('maxlength', '280')
    await a11yAudit()
  })
})
