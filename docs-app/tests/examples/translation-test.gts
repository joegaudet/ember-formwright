import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import { RichTextHarness } from '@ember-formwright/tiptap/test-support'
import NoteForm, { createModel } from 'docs-app/examples/translation'

class NoteHarness extends FormHarness {
  static formName = 'note'
  @field(InputHarness) declare title: InputHarness
  @field(RichTextHarness) declare body: RichTextHarness
}

module('Example | translation', function (hooks) {
  setupRenderingTest(hooks)

  test('arguments name the built-in buttons', async function (assert) {
    const model = createModel()
    await render(<template><NoteForm @model={{model}} /></template>)
    const note = new NoteHarness()

    assert.dom('[data-test-fw-submit]').hasText('Guardar')
    assert.dom('[data-test-fw-reset]').hasText('Repor')
    assert.dom('[role="toolbar"]').hasAttribute('aria-label', 'Formatação')
    assert.dom('[data-test-fw-tool="bold"]').hasAttribute('aria-label', 'Negrito')

    await note.title.fillIn('Notas')
    assert.dom('[data-test-fw-commit]').hasAttribute('aria-label', 'Aplicar')
    assert.dom('[data-test-fw-cancel]').hasAttribute('aria-label', 'Cancelar')
    await a11yAudit()
  })
})
