import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, RadioHarness, field } from '@ember-formwright/test-support'
import MemberForm, { createModel } from 'docs-app/examples/layouts-horizontal'

class MemberHarness extends FormHarness {
  static formName = 'member'
  @field(InputHarness) declare email: InputHarness
  @field(RadioHarness) declare role: RadioHarness
}

module('Example | layouts-horizontal', function (hooks) {
  setupRenderingTest(hooks)

  test('labels sit in their own column; the harness reads the fields as before', async function (assert) {
    const model = createModel()
    await render(<template><MemberForm @model={{model}} /></template>)
    const member = new MemberHarness()

    assert.dom('[data-test-fw-field="email"] > .fw-horizontal-label + .fw-horizontal-body').exists()
    assert.strictEqual(member.email.hint, 'Where invites go')
    await member.email.fillIn('ada@example.com')
    await member.role.select('admin')
    assert.strictEqual(model.email, 'ada@example.com')
    assert.strictEqual(model.role, 'admin')
    await a11yAudit()
  })
})
