import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, fillIn, getRootElement, settled, triggerEvent } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { Form, type Message, type Translator } from '@ember-formwright/ember'
import {
  FormHarness,
  field,
  registerTranslator,
  pseudoTranslator,
} from '@ember-formwright/test-support'
import { registerFileUploadControls } from '@ember-formwright/file-upload'
import { FileUploadHarness } from '@ember-formwright/file-upload/test-support'
import { registerTiptapControl } from '@ember-formwright/tiptap'
import { registerPowerCalendarControls } from '@ember-formwright/power-calendar'

registerFileUploadControls()
registerTiptapControl()
registerPowerCalendarControls()

class Model {
  @tracked name = 'Ada'
  @tracked resume: { name: string } | null = { name: '«cv.pdf»' }
  @tracked attachments: File[] = []
  @tracked body = ''
  @tracked departure: string | null = null
}

class TestForm extends FormHarness {
  @field(FileUploadHarness) declare resume: FileUploadHarness
  @field(FileUploadHarness) declare attachments: FileUploadHarness
}

const pdf = (name: string) => new File([new Uint8Array(10)], name, { type: 'application/pdf' })
const exe = (name: string) => new File([new Uint8Array(10)], name, { type: 'application/x-exe' })

/** The user's own data, which no translator touches: sizes and the `@accept` list. */
const OWN_DATA = '.fw-file-size, .fw-dropzone-accept'

/**
 * Every string a person sees or hears in `root`: text nodes (not hidden, not inside an element
 * that its own aria-label names), and aria-label, title and placeholder attributes.
 */
function visibleStrings(root: Node): string[] {
  const strings: string[] = []
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT)
  for (let node = walker.nextNode(); node; node = walker.nextNode()) {
    if (node instanceof Element) {
      for (const name of ['aria-label', 'title', 'placeholder', 'aria-placeholder']) {
        const value = node.getAttribute(name)
        if (value?.trim()) strings.push(value)
      }
      continue
    }
    const text = node.textContent?.trim()
    const parent = node.parentElement
    if (!text || !parent) continue
    if (parent.closest('[aria-hidden="true"], [aria-label], style, script')) continue
    if (parent.closest(OWN_DATA)) continue
    strings.push(text)
  }
  return strings
}

/** The test's own data is in «» (file names keep their extension); translated is in ⟦⟧. */
const isTestData = (s: string) => /^«[^«»]*»(\.\w+)?$/.test(s)
const isTranslated = (s: string) => s.startsWith('⟦') && s.endsWith('⟧')

/** The strings that skipped the translator. */
const untranslated = () =>
  visibleStrings(getRootElement()).filter(s => !isTestData(s) && !isTranslated(s))

class SwitchableTranslator implements Translator {
  @tracked locale = 'en'
  t(message: Message, values?: Record<string, unknown>): string {
    return this.locale === 'fr' ? `fr:${message.id}` : pseudoTranslator.t(message, values)
  }
}

module('Integration | i18n', function (hooks) {
  setupRenderingTest(hooks)

  test('a pseudo-locale translator wraps every built-in string', async function (assert) {
    registerTranslator(pseudoTranslator)
    const model = new Model()
    let fail: (reason?: unknown) => void = () => {}
    const upload = () =>
      new Promise((_resolve, reject) => {
        fail = reject
      })
    const ui = new TestForm()

    await render(
      <template>
        <Form @model={{model}} @requireConfirm={{true}} as |f|>
          <f.Field @for="name" @label="«Name»" />
          <f.Field @for="resume" @control="file" @label="«Résumé»" @optionLabel="name" />
          <f.Field @for="attachments" @control="files" @label="«Files»" as |field|>
            <field.Control @accept=".pdf" @upload={{upload}} />
          </f.Field>
          <f.Field @for="body" @control="rich-text" @label="«Body»" @placeholder="«Write»" />
          <f.Field
            @for="departure"
            @control="date-picker"
            @label="«Departure»"
            @placeholder="«Pick»"
          />
          <f.Submit />
          <f.Reset />
        </Form>
      </template>,
    )
    await fillIn('[data-test-fw-field="name"] input', '«Grace»')
    assert.dom('[data-test-fw-commit]').exists('the confirm buttons are shown')
    await triggerEvent(ui.attachments.dropzone, 'dragenter', {
      dataTransfer: { files: [], types: ['Files'], items: [] },
    })
    assert.dom('[data-test-fw-field="attachments"] .fw-dropzone-text strong').exists()
    assert.deepEqual(
      untranslated(),
      [],
      'while dragging: every built-in string goes through the translator',
    )

    await triggerEvent(ui.attachments.dropzone, 'dragleave')
    await ui.attachments.drop(exe('«setup».exe'))
    assert.dom('[data-test-fw-file-rejected]').exists()
    await ui.attachments.select(pdf('«a».pdf'))
    assert.dom('progress').exists('an upload is in flight')
    assert.deepEqual(
      untranslated(),
      [],
      'uploading: every built-in string goes through the translator',
    )

    fail(undefined)
    await ui.attachments.waitForUploads()
    assert.dom('[data-test-fw-retry]').exists('the upload failed')
    assert.deepEqual(
      untranslated(),
      [],
      'failed upload: every built-in string goes through the translator',
    )
  })

  test('the translator follows a tracked locale', async function (assert) {
    const translator = new SwitchableTranslator()
    registerTranslator(translator)
    const model = new Model()
    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" />
          <f.Submit />
        </Form>
      </template>,
    )
    assert.dom('[data-test-fw-submit]').hasText('⟦Śũƀɱĩţ⟧')
    translator.locale = 'fr'
    await settled()
    assert.dom('[data-test-fw-submit]').hasText('fr:formwright.form.submit')
    assert
      .dom('[data-test-fw-tool="bold"]')
      .hasAttribute('aria-label', 'fr:formwright.richText.bold')
  })

  test('an explicit argument wins over the translator', async function (assert) {
    registerTranslator(pseudoTranslator)
    const model = new Model()
    const ui = new TestForm()
    const removeLabel = (name: string) => `Delete ${name}`
    const rejectedLabel = (names: string) => `Nope: ${names}`
    const uploadingLabel = (name: string) => `Sending ${name}`
    let fail: (reason?: unknown) => void = () => {}
    const upload = () =>
      new Promise((_resolve, reject) => {
        fail = reject
      })
    const toolLabels = { bold: 'Strong', 'heading-2': 'Title' }

    await render(
      <template>
        <Form @model={{model}} @requireConfirm={{true}} as |f|>
          <f.Field @for="name" @label="Name" @applyLabel="Keep" @cancelLabel="Undo" />
          <f.Field @for="resume" @control="file" @label="Résumé" @optionLabel="name" as |field|>
            <field.Control @prompt="Pick one" @removeLabel={{removeLabel}} />
          </f.Field>
          <f.Field @for="attachments" @control="files" @label="Files" as |field|>
            <field.Control
              @accept=".pdf"
              @upload={{upload}}
              @dropLabel="Let go"
              @dropHint="or drag it in"
              @rejectedLabel={{rejectedLabel}}
              @uploadingLabel={{uploadingLabel}}
              @retryLabel="Again"
            />
          </f.Field>
          <f.Field @for="body" @control="rich-text" @label="Body" as |field|>
            <field.Control @toolbarLabel="Styles" @toolLabels={{toolLabels}} />
          </f.Field>
          <f.Submit @text="Save" />
          <f.Reset @text="Start over" />
        </Form>
      </template>,
    )
    assert.dom('[data-test-fw-submit]').hasText('Save')
    assert.dom('[data-test-fw-reset]').hasText('Start over')
    assert.dom('[data-test-fw-field="resume"] .fw-dropzone-prompt').hasText('Pick one')
    assert
      .dom('[data-test-fw-field="attachments"] .fw-dropzone-text')
      .hasText('⟦Ćĥōōśē ƒĩĺēś⟧ or drag it in')
    assert.dom('[data-test-fw-remove="«cv.pdf»"]').hasAttribute('aria-label', 'Delete «cv.pdf»')
    assert.dom('.fw-rich-text-toolbar').hasAttribute('aria-label', 'Styles')
    assert.dom('[data-test-fw-tool="bold"]').hasAttribute('aria-label', 'Strong')
    assert.dom('[data-test-fw-tool="heading-2"]').hasAttribute('title', 'Title')
    assert
      .dom('[data-test-fw-tool="italic"]')
      .hasAttribute('aria-label', '⟦Ĩţàĺĩć⟧', 'tools without a label still translate')

    await fillIn('[data-test-fw-field="name"] input', 'Grace')
    assert.dom('[data-test-fw-commit]').hasAttribute('aria-label', 'Keep')
    assert.dom('[data-test-fw-cancel]').hasAttribute('aria-label', 'Undo')

    await triggerEvent(ui.attachments.dropzone, 'dragenter', {
      dataTransfer: { files: [], types: ['Files'], items: [] },
    })
    assert.dom('[data-test-fw-field="attachments"] .fw-dropzone-text').hasText('Let go')
    await triggerEvent(ui.attachments.dropzone, 'dragleave')
    await ui.attachments.drop(exe('setup.exe'))
    assert.strictEqual(ui.attachments.rejected, 'Nope: setup.exe')
    await ui.attachments.select(pdf('a.pdf'))
    assert.dom('progress').hasAttribute('aria-label', 'Sending a.pdf')
    fail(new Error('Boom'))
    await ui.attachments.waitForUploads()
    assert.dom('[data-test-fw-retry]').hasText('Again')
  })

  test('without a translator, the strings are English', async function (assert) {
    const model = new Model()
    model.resume = { name: 'cv.pdf' }
    const ui = new TestForm()
    let fail: (reason?: unknown) => void = () => {}
    const upload = () =>
      new Promise((_resolve, reject) => {
        fail = reject
      })

    await render(
      <template>
        <Form @model={{model}} @requireConfirm={{true}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Field @for="resume" @control="file" @label="Résumé" @optionLabel="name" />
          <f.Field @for="attachments" @control="files" @label="Files" as |field|>
            <field.Control @accept=".pdf" @upload={{upload}} />
          </f.Field>
          <f.Field @for="body" @control="rich-text" @label="Body" />
          <f.Field @for="departure" @control="date-picker" @label="Departure" @placeholder="Pick" />
          <f.Submit />
          <f.Reset />
        </Form>
      </template>,
    )
    assert.dom('[data-test-fw-submit]').hasText('Submit')
    assert.dom('[data-test-fw-reset]').hasText('Reset')
    assert.dom('[data-test-fw-field="resume"] .fw-dropzone-prompt').hasText('Choose a file')
    assert
      .dom('[data-test-fw-field="attachments"] .fw-dropzone-text')
      .hasText('Choose files or drop here')
    assert.dom('[data-test-fw-remove="cv.pdf"]').hasAttribute('aria-label', 'Remove cv.pdf')
    assert.dom('.fw-rich-text-toolbar').hasAttribute('aria-label', 'Formatting')
    assert.deepEqual(
      [...getRootElement().querySelectorAll('[data-test-fw-tool]')].map(b =>
        b.getAttribute('aria-label'),
      ),
      [
        'Bold',
        'Italic',
        'Strikethrough',
        'Heading 2',
        'Heading 3',
        'Bulleted list',
        'Numbered list',
        'Quote',
        'Undo',
        'Redo',
      ],
    )
    assert.dom('.fw-date-picker').hasAttribute('aria-label', 'Departure: Pick')

    await fillIn('[data-test-fw-field="name"] input', 'Grace')
    assert.dom('[data-test-fw-commit]').hasAttribute('aria-label', 'Apply')
    assert.dom('[data-test-fw-cancel]').hasAttribute('aria-label', 'Cancel')

    await triggerEvent(ui.attachments.dropzone, 'dragenter', {
      dataTransfer: { files: [], types: ['Files'], items: [] },
    })
    assert.dom('[data-test-fw-field="attachments"] .fw-dropzone-text').hasText('Drop to add')
    await triggerEvent(ui.attachments.dropzone, 'dragleave')
    await ui.attachments.drop(exe('setup.exe'))
    assert.strictEqual(ui.attachments.rejected, 'Not an accepted type: setup.exe')
    await ui.attachments.select(pdf('a.pdf'))
    assert.dom('progress').hasAttribute('aria-label', 'Uploading a.pdf')
    fail(undefined)
    await ui.attachments.waitForUploads()
    assert.dom('[data-test-fw-retry]').hasText('Retry')
    assert.dom('[data-test-fw-upload-error]').hasText('Upload failed')
    await click('[data-test-fw-retry]')
  })
})
