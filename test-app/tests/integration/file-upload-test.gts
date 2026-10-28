import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, triggerEvent, focus, waitUntil } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { FormHarness, field } from '@ember-formwright/test-support'
import { registerFileUploadControls, type UploadFn } from '@ember-formwright/file-upload'
import { FileUploadHarness } from '@ember-formwright/file-upload/test-support'
import type { UploadFile } from 'ember-file-upload'

registerFileUploadControls()

interface Stored {
  id: number
  name: string
}

class Application {
  @tracked resume: File | Stored | null = null
  @tracked attachments: (File | Stored)[] = []
}

class ApplicationForm extends FormHarness {
  @field(FileUploadHarness) declare resume: FileUploadHarness
  @field(FileUploadHarness) declare attachments: FileUploadHarness
}

const pdf = (name: string, bytes = 2048) =>
  new File([new Uint8Array(bytes)], name, { type: 'application/pdf' })
const png = (name: string) => new File([new Uint8Array(10)], name, { type: 'image/png' })

/** An upload the test settles by hand. */
function deferredUploads() {
  const pending = new Map<
    string,
    { file: UploadFile; resolve: (v: unknown) => void; reject: (e: Error) => void }
  >()
  const upload: UploadFn = file =>
    new Promise((resolve, reject) => {
      file.progress = 40
      pending.set(file.name, { file, resolve, reject })
    })
  return { pending, upload }
}

module('Integration | file-upload', function (hooks) {
  setupRenderingTest(hooks)

  let ui: ApplicationForm
  hooks.beforeEach(function () {
    ui = new ApplicationForm()
  })

  test('file stores the chosen File, with the field wired to the native input', async function (assert) {
    const model = new Application()

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="resume" @control="file" @label="Résumé" @hint="A PDF" @required={{true}} />
        </Form>
      </template>,
    )

    const input = ui.resume.input
    assert.strictEqual(input.type, 'file')
    assert
      .dom('[data-test-fw-field="resume"] label[data-test-fw-label]')
      .hasAttribute('for', input.id)
    assert.dom(input).hasAttribute('aria-label', 'Résumé')
    assert.dom(input).hasAttribute('aria-describedby', `${input.id}-hint`)
    assert.dom(input).isRequired()
    assert.dom(input).doesNotHaveAttribute('multiple')
    assert
      .dom('[data-test-fw-field="resume"] [data-test-fw-control]')
      .hasAttribute('data-test-fw-control', 'file')
      .hasAttribute('data-fw-name', 'form.resume')
    assert.dom('[data-test-fw-field="resume"] .fw-dropzone-prompt').hasText('Choose a file')

    const cv = pdf('cv.pdf')
    await ui.resume.select(cv)
    assert.strictEqual(model.resume, cv, 'stores the File itself')
    assert.deepEqual(ui.resume.files, ['cv.pdf'])
    assert.dom('[data-test-fw-file="cv.pdf"] .fw-file-size').hasText('2 kB')
    assert.dom('[data-test-fw-file="cv.pdf"] .fw-file-kind').hasText('PDF')

    const other = pdf('cv-v2.pdf')
    await ui.resume.select(other)
    assert.strictEqual(model.resume, other, 'a single file replaces the last one')
    assert.deepEqual(ui.resume.files, ['cv-v2.pdf'])

    await ui.resume.remove('cv-v2.pdf')
    assert.strictEqual(model.resume, null)
    assert.deepEqual(ui.resume.files, [])
    await a11yAudit()
  })

  test('files appends chosen and dropped files, and removes one at a time', async function (assert) {
    const model = new Application()

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="attachments" @control="files" @label="Attachments" />
        </Form>
      </template>,
    )

    assert.dom(ui.attachments.input).hasAttribute('multiple')
    assert.dom('[data-test-fw-field="attachments"] .fw-dropzone-prompt').hasText('Choose files')

    await ui.attachments.select(pdf('a.pdf'), pdf('b.pdf'))
    await ui.attachments.drop(png('c.png'))
    assert.deepEqual(
      model.attachments.map(f => f.name),
      ['a.pdf', 'b.pdf', 'c.png'],
    )
    assert.deepEqual(ui.attachments.files, ['a.pdf', 'b.pdf', 'c.png'])

    await ui.attachments.remove('b.pdf')
    assert.deepEqual(
      model.attachments.map(f => f.name),
      ['a.pdf', 'c.png'],
    )
    await a11yAudit()
  })

  test('dropping several files on a single file field takes the first', async function (assert) {
    const model = new Application()
    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="resume" @control="file" @label="Résumé" />
        </Form>
      </template>,
    )

    await ui.resume.drop(pdf('first.pdf'), pdf('second.pdf'))
    assert.strictEqual((model.resume as File).name, 'first.pdf')
    assert.deepEqual(ui.resume.files, ['first.pdf'])
  })

  test('dragging over the zone highlights it', async function (assert) {
    const model = new Application()
    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="resume" @control="file" @label="Résumé" />
        </Form>
      </template>,
    )

    const dataTransfer = { files: [pdf('x.pdf')], types: ['Files'], items: [] }
    await triggerEvent(ui.resume.dropzone, 'dragenter', { dataTransfer })
    assert.dom('[data-test-fw-field="resume"] .fw-dropzone-body').hasAttribute('data-active')
    assert.dom('[data-test-fw-field="resume"] .fw-dropzone-text').hasText('Drop to add')
    await triggerEvent(ui.resume.dropzone, 'dragleave', { dataTransfer })
    assert
      .dom('[data-test-fw-field="resume"] .fw-dropzone-body')
      .doesNotHaveAttribute('data-active')
  })

  test('@accept filters the picker and the drop zone, and says what it turned away', async function (assert) {
    const model = new Application()
    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="attachments" @control="files" @label="Attachments" as |field|>
            <field.Control @accept=".pdf,image/*" />
          </f.Field>
        </Form>
      </template>,
    )

    assert.dom(ui.attachments.input).hasAttribute('accept', '.pdf,image/*')
    assert.dom('[data-test-fw-field="attachments"] .fw-dropzone-accept').hasText('.pdf,image/*')

    const exe = new File(['x'], 'setup.exe', { type: 'application/x-msdownload' })
    await ui.attachments.drop(pdf('ok.pdf'), exe, png('ok.png'))
    assert.deepEqual(ui.attachments.files, ['ok.pdf', 'ok.png'])
    assert.strictEqual(ui.attachments.rejected, 'Not an accepted type: setup.exe')

    await ui.attachments.select(exe)
    assert.deepEqual(ui.attachments.files, ['ok.pdf', 'ok.png'], 'the picker filters too')
    assert.strictEqual(ui.attachments.rejected, undefined, 'a new choice clears the message')
  })

  test('the list follows the value, so reset brings back what was there', async function (assert) {
    const model = new Application()
    const original = pdf('original.pdf')
    model.resume = original

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="resume" @control="file" @label="Résumé" />
          <f.Reset />
        </Form>
      </template>,
    )

    assert.deepEqual(ui.resume.files, ['original.pdf'])
    await ui.resume.select(pdf('new.pdf'))
    assert.deepEqual(ui.resume.files, ['new.pdf'])
    assert.true(ui.resume.isDirty)

    await ui.reset()
    assert.strictEqual(model.resume, original)
    assert.deepEqual(ui.resume.files, ['original.pdf'])
  })

  test('@upload uploads straight away, shows progress, and stores the result', async function (assert) {
    const model = new Application()
    const { pending, upload } = deferredUploads()
    let next = 1
    const resolveWith = (name: string) => pending.get(name)!.resolve({ id: next++, name })

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="attachments" @control="files" @label="Attachments" as |field|>
            <field.Control @upload={{upload}} />
          </f.Field>
        </Form>
      </template>,
    )

    await ui.attachments.select(pdf('a.pdf'), pdf('b.pdf'))
    assert.deepEqual(ui.attachments.uploading, ['a.pdf', 'b.pdf'])
    assert.deepEqual(model.attachments, [], 'nothing is stored until an upload succeeds')
    assert.strictEqual(pending.get('a.pdf')!.file.file.name, 'a.pdf', 'upload gets an UploadFile')
    assert
      .dom('[data-test-fw-file="a.pdf"] progress')
      .hasAttribute('aria-label', 'Uploading a.pdf')
      .hasProperty('value', 40)
    assert
      .dom('[data-test-fw-field="attachments"] [data-test-fw-control]')
      .hasAttribute('data-uploading')
      .hasAttribute('aria-busy', 'true')
    await a11yAudit()

    resolveWith('b.pdf')
    await waitUntil(() => model.attachments.length === 1)
    assert.deepEqual(ui.attachments.uploading, ['a.pdf'])
    resolveWith('a.pdf')
    await ui.attachments.waitForUploads()
    assert.deepEqual(model.attachments, [
      { id: 1, name: 'b.pdf' },
      { id: 2, name: 'a.pdf' },
    ])
    assert.deepEqual(ui.attachments.files, ['b.pdf', 'a.pdf'], 'stored values show their name')
    assert
      .dom('[data-test-fw-field="attachments"] [data-test-fw-control]')
      .doesNotHaveAttribute('data-uploading')
  })

  test('a failed upload stores nothing, and can be retried or dismissed', async function (assert) {
    const model = new Application()
    const { pending, upload } = deferredUploads()

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="resume" @control="file" @label="Résumé" @optionLabel="name" as |field|>
            <field.Control @upload={{upload}} />
          </f.Field>
        </Form>
      </template>,
    )

    await ui.resume.select(pdf('cv.pdf'))
    pending.get('cv.pdf')!.reject(new Error('The server said no'))
    await ui.resume.waitForUploads()
    assert.deepEqual(ui.resume.failed, ['cv.pdf'])
    assert.dom('[data-test-fw-upload-error]').hasText('The server said no')
    assert.strictEqual(model.resume, null)
    await a11yAudit()

    await ui.resume.retry('cv.pdf')
    assert.deepEqual(ui.resume.uploading, ['cv.pdf'])
    pending.get('cv.pdf')!.resolve({ id: 7, name: 'cv.pdf' })
    await ui.resume.waitForUploads()
    assert.deepEqual(model.resume, { id: 7, name: 'cv.pdf' })
    assert.deepEqual(ui.resume.files, ['cv.pdf'])

    await ui.resume.select(pdf('other.pdf'))
    pending.get('other.pdf')!.reject(new Error('Nope'))
    await ui.resume.waitForUploads()
    await ui.resume.remove('other.pdf')
    assert.deepEqual(ui.resume.files, ['cv.pdf'], 'dismissing a failure keeps the stored file')
    assert.deepEqual(model.resume, { id: 7, name: 'cv.pdf' })
  })

  test('errors mark the input invalid and describe it', async function (assert) {
    const model = new Application()
    const validator = (a: Application): ErrorMap =>
      a.resume ? {} : { resume: ['Attach your résumé'] }

    await render(
      <template>
        <Form @model={{model}} @validator={{validator}} as |f|>
          <f.Field @for="resume" @control="file" @label="Résumé" />
          <f.Submit>Apply</f.Submit>
        </Form>
      </template>,
    )

    await ui.submit()
    assert.deepEqual(ui.resume.errors, ['Attach your résumé'])
    assert.dom(ui.resume.input).hasAttribute('aria-invalid', 'true')
    assert.dom(ui.resume.input).hasAttribute('aria-describedby', `${ui.resume.input.id}-errors`)
    assert.dom(ui.resume.input).isFocused('focus moves to the invalid input')
    await a11yAudit()

    await ui.resume.select(pdf('cv.pdf'))
    assert.deepEqual(ui.resume.errors, [])
  })

  test('disabled and readonly: no choosing, dropping or removing', async function (assert) {
    const model = new Application()
    model.attachments = [pdf('kept.pdf')]
    const other = new ApplicationForm('other')

    await render(
      <template>
        <Form @model={{model}} @readonly={{true}} as |f|>
          <f.Field @for="attachments" @control="files" @label="Attachments" />
        </Form>
        <Form @model={{model}} @disabled={{true}} @name="other" as |f|>
          <f.Field @for="attachments" @control="files" @label="Attachments" />
        </Form>
      </template>,
    )

    for (const form of [ui, other]) {
      assert.true(form.attachments.isDisabled)
      assert.dom(form.attachments.input).isDisabled()
      assert.deepEqual(form.attachments.files, ['kept.pdf'])
      assert.dom('[data-test-fw-remove]', form.attachments.element).doesNotExist()
      await form.attachments.drop(pdf('dropped.pdf'))
      assert.deepEqual(form.attachments.files, ['kept.pdf'], 'a drop is ignored')
    }
    assert.deepEqual(
      model.attachments.map(f => f.name),
      ['kept.pdf'],
    )
  })

  test('inline mode shows the file by name, and edits with the input focused', async function (assert) {
    const model = new Application()
    model.attachments = [pdf('a.pdf'), { id: 3, name: 'b.pdf' }]

    await render(
      <template>
        <Form @model={{model}} @inline={{true}} as |f|>
          <f.Field @for="attachments" @control="files" @label="Attachments" />
        </Form>
      </template>,
    )

    assert.strictEqual(ui.attachments.displayText, 'a.pdf, b.pdf')
    await ui.attachments.edit()
    assert.dom(ui.attachments.input).isFocused()
    await ui.attachments.select(pdf('c.pdf'))
    assert.strictEqual(model.attachments.length, 2, 'waits for the commit')
    await ui.attachments.commit()
    assert.strictEqual(ui.attachments.displayText, 'a.pdf, b.pdf, c.pdf')
  })

  test('the label opens the picker, and the zone shows focus', async function (assert) {
    const model = new Application()
    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="resume" @control="file" @label="Résumé" />
        </Form>
      </template>,
    )

    let opened = 0
    ui.resume.input.addEventListener('click', () => opened++)
    ui.resume.input.addEventListener('click', e => e.preventDefault())
    await click('[data-test-fw-field="resume"] .fw-dropzone-label')
    assert.strictEqual(opened, 1, 'the drop zone is a label for the input')
    await focus(ui.resume.input)
    assert.dom(ui.resume.input).isFocused()
  })
})
