import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, CheckboxHarness, field } from '@formwright/test-support'
import HandleForm, { createModel } from 'docs-app/examples/validation-function'

class HandleHarness extends FormHarness {
  static formName = 'handle'
  @field(InputHarness) declare username: InputHarness
  @field(CheckboxHarness) declare agree: CheckboxHarness
}

module('Example | validation-function', function (hooks) {
  setupRenderingTest(hooks)

  test('async field errors and form-level errors', async function (assert) {
    const model = createModel()
    await render(<template><HandleForm @model={{model}} /></template>)
    const handle = new HandleHarness()

    await handle.username.fillIn('Ada')
    await handle.submit()
    assert.deepEqual(handle.username.errors, ['That username is taken'])
    assert.deepEqual(handle.errors, ['Please accept the code of conduct to continue.'])
    await a11yAudit()

    await handle.username.fillIn('countess')
    await handle.agree.check()
    assert.deepEqual(handle.username.errors, [])
    assert.deepEqual(handle.errors, [])
    assert.true(model.agree)
  })
})
