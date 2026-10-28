import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render, click } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import DocForm, { createModel } from 'docs-app/examples/layouts-actions'

class DocHarness extends FormHarness {
  static formName = 'doc'
  @field(InputHarness) declare title: InputHarness
}

module('Example | layouts-actions', function (hooks) {
  setupRenderingTest(hooks)

  test('save and cancel on the left, delete on the right', async function (assert) {
    const model = createModel()
    await render(<template><DocForm @model={{model}} /></template>)
    const doc = new DocHarness()

    await doc.title.fillIn('Annual report')
    await doc.reset()
    assert.strictEqual(model.title, 'Quarterly report', 'Cancel resets')

    await click('.fw-actions-right [data-test-fw-button]')
    assert.true(model.deleted)
    await a11yAudit()
  })
})
