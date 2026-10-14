import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@formwright/test-support'
import ContactCard, { createModel } from 'docs-app/examples/inline-editing'

class InlineHarness extends FormHarness {
  static formName = 'inline'
  @field(InputHarness) declare name: InputHarness
}

class CalloutHarness extends FormHarness {
  static formName = 'callout'
  @field(InputHarness) declare phone: InputHarness
}

module('Example | inline-editing', function (hooks) {
  setupRenderingTest(hooks)

  test('click a value, edit it, apply it', async function (assert) {
    const model = createModel()
    await render(<template><ContactCard @model={{model}} /></template>)
    const inline = new InlineHarness()
    const callout = new CalloutHarness()

    assert.strictEqual(inline.name.displayText, 'Grace Hopper')
    await inline.name.edit()
    await inline.name.fillIn('Amazing Grace')
    await inline.name.commit()
    assert.strictEqual(model.name, 'Amazing Grace')

    assert.strictEqual(callout.phone.displayText, 'Add a phone number')
    await callout.phone.edit()
    assert.dom('[popover]').exists('edits in a native popover')
    await callout.phone.fillIn('555-0100')
    await callout.phone.cancel()
    assert.strictEqual(model.phone, '', 'cancel discards the edit')
    await a11yAudit()
  })
})
