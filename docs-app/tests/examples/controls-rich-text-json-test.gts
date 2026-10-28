import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, field } from '@ember-formwright/test-support'
import { RichTextHarness } from '@ember-formwright/tiptap/test-support'
import CommentForm, { createModel } from 'docs-app/examples/controls-rich-text-json'

class CommentHarness extends FormHarness {
  static formName = 'comment'
  @field(RichTextHarness) declare body: RichTextHarness
}

module('Example | controls-rich-text-json', function (hooks) {
  setupRenderingTest(hooks)

  test('a trimmed toolbar, storing JSON', async function (assert) {
    const model = createModel()
    await render(<template><CommentForm @model={{model}} /></template>)
    const comment = new CommentHarness()

    assert.deepEqual(comment.body.tools, ['bold', 'italic', 'bullet-list'])
    await comment.submit()
    assert.deepEqual(comment.body.errors, ['Write a comment first'])

    await comment.body.typeText('Looks good')
    assert.deepEqual(comment.body.errors, [])
    assert.deepEqual(model.body, {
      type: 'doc',
      content: [{ type: 'paragraph', content: [{ type: 'text', text: 'Looks good' }] }],
    })
    await a11yAudit()
  })
})
