import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import SignupForm, { createModel } from 'docs-app/examples/getting-started'

class SignupHarness extends FormHarness {
  static formName = 'signup'
  @field(InputHarness) declare name: InputHarness
  @field(InputHarness) declare email: InputHarness
}

module('Example | getting-started', function (hooks) {
  setupRenderingTest(hooks)

  test('typing writes to the model', async function (assert) {
    const model = createModel()
    await render(<template><SignupForm @model={{model}} /></template>)

    const signup = new SignupHarness()
    await signup.name.fillIn('Ada')
    await signup.email.fillIn('ada@example.com')

    assert.strictEqual(model.name, 'Ada')
    assert.strictEqual(model.email, 'ada@example.com')
    assert.strictEqual(signup.email.hint, 'We never share it.')
    await a11yAudit()
  })
})
