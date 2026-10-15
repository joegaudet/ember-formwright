import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import TextControls, { createModel } from 'docs-app/examples/controls-text'

class PersonHarness extends FormHarness {
  static formName = 'person'
  @field(InputHarness) declare email: InputHarness
  @field(InputHarness) declare birthday: InputHarness
  @field(InputHarness) declare color: InputHarness
}

module('Example | controls-text', function (hooks) {
  setupRenderingTest(hooks)

  test('each control is the matching native input', async function (assert) {
    const model = createModel()
    await render(<template><TextControls @model={{model}} /></template>)
    const person = new PersonHarness()

    assert.dom(person.email.control).hasAttribute('type', 'email')
    assert.dom('[data-test-fw-field="meeting"] input').hasAttribute('type', 'datetime-local')
    await person.birthday.fillIn('1815-12-10')
    assert.strictEqual(model.birthday, '1815-12-10')
    assert.strictEqual(person.color.value, '#4f46e5')
    await a11yAudit()
  })
})
