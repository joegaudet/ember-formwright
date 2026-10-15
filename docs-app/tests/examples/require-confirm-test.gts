import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render, triggerKeyEvent } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import AccountForm, { createModel } from 'docs-app/examples/require-confirm'

class AccountHarness extends FormHarness {
  static formName = 'account'
  @field(InputHarness) declare username: InputHarness
}

module('Example | require-confirm', function (hooks) {
  setupRenderingTest(hooks)

  test('changes wait for ✔ or Enter; Esc cancels', async function (assert) {
    const model = createModel()
    await render(<template><AccountForm @model={{model}} /></template>)
    const account = new AccountHarness()

    await account.username.fillIn('countess')
    assert.strictEqual(model.username, 'ada', 'not applied yet')
    await triggerKeyEvent(account.username.control, 'keydown', 'Enter')
    assert.strictEqual(model.username, 'countess')

    await account.username.fillIn('nope')
    await triggerKeyEvent(account.username.control, 'keydown', 'Escape')
    assert.strictEqual(model.username, 'countess')
    await a11yAudit()
  })
})
