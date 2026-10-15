import { module, test } from 'qunit'
import { visit } from '@ember/test-helpers'
import { setupApplicationTest } from 'ember-qunit'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'

class SignupForm extends FormHarness {
  static formName = 'signup'

  @field(InputHarness) name
  @field(InputHarness) email
}

module('Acceptance | signup', function (hooks) {
  setupApplicationTest(hooks)

  test('the v2 addon works in a classic ember-cli build', async function (assert) {
    await visit('/')
    const signup = new SignupForm()

    await signup.name.fillIn('Ada')
    await signup.submit()
    assert.deepEqual(signup.email.errors, ['Email is required'])

    await signup.email.fillIn('ada@example.com')
    assert.deepEqual(signup.email.errors, [])
  })
})
