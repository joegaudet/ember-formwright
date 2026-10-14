import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, NumberHarness, field } from '@formwright/test-support'
import RegistrationForm, { createModel } from 'docs-app/examples/validation-zod'

class RegistrationHarness extends FormHarness {
  static formName = 'registration'
  @field(InputHarness) declare email: InputHarness
  @field(InputHarness) declare password: InputHarness
  @field(InputHarness) declare confirm: InputHarness
  @field(NumberHarness) declare age: NumberHarness
}

module('Example | validation-zod', function (hooks) {
  setupRenderingTest(hooks)

  test('schema issues land on their fields and clear as they are fixed', async function (assert) {
    const model = createModel()
    await render(<template><RegistrationForm @model={{model}} /></template>)
    const registration = new RegistrationHarness()

    await registration.email.fillIn('ada@')
    await registration.password.fillIn('analytical')
    await registration.confirm.fillIn('engine')
    await registration.submit()

    assert.deepEqual(registration.email.errors, ['That email looks off'])
    assert.deepEqual(registration.confirm.errors, ['Passwords must match'])
    assert.deepEqual(registration.age.errors, ['Enter your age'])
    assert.dom(registration.email.control).isFocused('focus moves to the first invalid field')
    await a11yAudit()

    await registration.confirm.fillIn('analytical')
    assert.deepEqual(registration.confirm.errors, [])
    assert.strictEqual(model.confirm, 'analytical')
  })
})
