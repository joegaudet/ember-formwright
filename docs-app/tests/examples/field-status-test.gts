import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import AccountForm, { createModel } from 'docs-app/examples/field-status'

class AccountHarness extends FormHarness {
  static formName = 'account'
  @field(InputHarness) declare username: InputHarness
}

module('Example | field-status', function (hooks) {
  setupRenderingTest(hooks)

  test('a field goes idle, pending while it holds a value, then idle again', async function (assert) {
    const model = createModel()
    await render(<template><AccountForm @model={{model}} /></template>)
    const account = new AccountHarness()

    assert.dom('.status-badge').hasText('idle')

    await account.username.fillIn('countess')
    assert.dom('.status-badge').hasText('pending')
    assert.dom('.status').includesText('press Enter or ✓ to apply it', 'status.isPending')

    await account.username.commit()
    assert.dom('.status-badge').hasText('idle')
    assert.strictEqual(model.username, 'countess')
    await a11yAudit()
  })
})
