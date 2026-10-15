import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import InviteForm, { createModel } from 'docs-app/examples/lifecycle'

class InviteHarness extends FormHarness {
  static formName = 'invite'
  @field(InputHarness) declare email: InputHarness
}

const logged = () =>
  [...document.querySelectorAll('.hook-log li')].map(li => li.textContent!.trim())

module('Example | lifecycle', function (hooks) {
  setupRenderingTest(hooks)

  test('hooks run in order', async function (assert) {
    const model = createModel()
    await render(<template><InviteForm @model={{model}} /></template>)
    const invite = new InviteHarness()

    await invite.submit()
    assert.deepEqual(logged(), ['didNotSubmit(email)'])

    await invite.email.fillIn('ada@example.com')
    await invite.submit()
    assert.deepEqual(logged().slice(1), [
      'onChange(email, "ada@example.com")',
      'willSubmit → true',
      'onSubmit(ada@example.com)',
      'didSubmit',
    ])
    await a11yAudit()
  })
})
