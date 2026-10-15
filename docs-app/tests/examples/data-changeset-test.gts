import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import AccountForm, { createModel } from 'docs-app/examples/data-changeset'

class AccountHarness extends FormHarness {
  static formName = 'account'
  @field(InputHarness) declare username: InputHarness
  @field(InputHarness) declare email: InputHarness
}

module('Example | data-changeset', function (hooks) {
  setupRenderingTest(hooks)

  test('edits stay in the changeset until a valid submit', async function (assert) {
    const changeset = createModel()
    const model = changeset.data
    await render(<template><AccountForm @model={{changeset}} /></template>)
    const account = new AccountHarness()

    await account.username.fillIn('grace')
    assert.strictEqual(model.username, 'ada', 'the model is untouched while editing')
    assert.dom('.status').hasText('Saved username: ada')

    await account.email.fillIn('not an email')
    await account.submit()
    assert.deepEqual(account.email.errors, ['Enter an email address'])
    assert.strictEqual(model.username, 'ada', 'an invalid changeset is not saved')

    await account.email.fillIn('grace@example.com')
    await account.submit()
    assert.strictEqual(model.username, 'grace')
    assert.dom('.status').hasText('Saved username: grace')

    await account.username.fillIn('hopper')
    await account.reset()
    assert.strictEqual(account.username.value, 'grace', 'reset rolls the changeset back')
    await a11yAudit()
  })
})
