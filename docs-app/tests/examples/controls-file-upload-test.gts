import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, field } from '@ember-formwright/test-support'
import { FileUploadHarness } from '@ember-formwright/file-upload/test-support'
import ApplicationForm, { createModel } from 'docs-app/examples/controls-file-upload'

class ApplicationHarness extends FormHarness {
  static formName = 'application'
  @field(FileUploadHarness) declare resume: FileUploadHarness
  @field(FileUploadHarness) declare samples: FileUploadHarness
}

module('Example | controls-file-upload', function (hooks) {
  setupRenderingTest(hooks)

  test('choose, drop and remove files', async function (assert) {
    const model = createModel()
    await render(<template><ApplicationForm @model={{model}} /></template>)
    const form = new ApplicationHarness()

    assert.deepEqual(form.resume.files, ['ada-lovelace-cv.pdf'])
    const cv = new File(['%PDF'], 'cv-2026.pdf', { type: 'application/pdf' })
    await form.resume.select(cv)
    assert.strictEqual(model.resume, cv, 'stores the File')

    const sketch = new File(['<svg/>'], 'sketch.svg', { type: 'image/svg+xml' })
    await form.samples.drop(sketch)
    assert.deepEqual(form.samples.files, ['analytical-engine.png', 'note-g.pdf', 'sketch.svg'])

    await form.samples.remove('note-g.pdf')
    assert.deepEqual(
      model.samples.map(file => file.name),
      ['analytical-engine.png', 'sketch.svg'],
    )
    await a11yAudit()
  })
})
