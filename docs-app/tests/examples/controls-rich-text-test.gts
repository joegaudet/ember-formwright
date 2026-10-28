import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import { RichTextHarness } from '@ember-formwright/tiptap/test-support'
import PostForm, { createModel } from 'docs-app/examples/controls-rich-text'

class PostHarness extends FormHarness {
  static formName = 'post'
  @field(InputHarness) declare title: InputHarness
  @field(RichTextHarness) declare body: RichTextHarness
}

module('Example | controls-rich-text', function (hooks) {
  setupRenderingTest(hooks)

  test('formats with the toolbar and stores HTML', async function (assert) {
    const model = createModel()
    await render(<template><PostForm @model={{model}} /></template>)
    const post = new PostHarness()

    await post.body.setContent('<p>Shipping today</p>')
    await post.body.selectAll()
    await post.body.press('bold')
    assert.true(post.body.isActive('bold'))
    assert.strictEqual(model.body, '<p><strong>Shipping today</strong></p>')

    await post.body.press('undo')
    assert.strictEqual(model.body, '<p>Shipping today</p>')
    await a11yAudit()
  })
})
