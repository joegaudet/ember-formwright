import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, field } from '@ember-formwright/test-support'
import { FileUploadHarness } from '@ember-formwright/file-upload/test-support'
import MessageForm, { createModel } from 'docs-app/examples/controls-file-upload-upload'

class MessageHarness extends FormHarness {
  static formName = 'message'
  @field(FileUploadHarness) declare attachments: FileUploadHarness
}

module('Example | controls-file-upload-upload', function (hooks) {
  setupRenderingTest(hooks)

  test('uploads as files are chosen, and stores the results', async function (assert) {
    const model = createModel()
    await render(<template><MessageForm @model={{model}} /></template>)
    const message = new MessageHarness()

    const notes = new File(['minutes'], 'notes.txt', { type: 'text/plain' })
    const huge = new File([new Uint8Array(2_000_000)], 'huge.mov', { type: 'video/quicktime' })
    await message.attachments.select(notes, huge)
    assert.deepEqual(message.attachments.uploading, ['notes.txt', 'huge.mov'])
    await a11yAudit()

    await message.attachments.waitForUploads()
    assert.deepEqual(
      model.attachments.map(a => a.name),
      ['notes.txt'],
      'stores what the upload resolved to',
    )
    assert.deepEqual(message.attachments.failed, ['huge.mov'])

    await message.attachments.remove('huge.mov')
    assert.deepEqual(message.attachments.files, ['notes.txt'])
  })
})
