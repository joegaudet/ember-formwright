import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import AccountForm, { createModel } from 'docs-app/examples/layouts-custom'

class AccountHarness extends FormHarness {
  static formName = 'account'
  @field(InputHarness) declare username: InputHarness
}

module('Example | layouts-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('errors above the control, still announced and still wired', async function (assert) {
    const model = createModel()
    await render(<template><AccountForm @model={{model}} /></template>)
    const account = new AccountHarness()

    await account.submit()
    assert.dom('[data-test-fw-field="username"] > .fw-errors + .fw-control-area').exists()
    assert.deepEqual(account.username.errors, ['At least 3 characters'])
    assert
      .dom(account.username.control)
      .hasAttribute(
        'aria-describedby',
        `${account.username.control.id}-hint ${account.username.control.id}-errors`,
      )
    await a11yAudit()

    await account.username.fillIn('ada')
    assert.deepEqual(account.username.errors, [])
  })
})
