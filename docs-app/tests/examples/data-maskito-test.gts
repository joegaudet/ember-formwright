import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render, settled } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import AddressForm, { createModel } from 'docs-app/examples/data-maskito'

class AddressHarness extends FormHarness {
  static formName = 'address'
  @field(InputHarness) declare phone: InputHarness
}

module('Example | data-maskito', function (hooks) {
  setupRenderingTest(hooks)

  test('the mask shapes what is typed', async function (assert) {
    const model = createModel()
    await render(<template><AddressForm @model={{model}} /></template>)
    const address = new AddressHarness()

    const input = address.phone.control as HTMLInputElement
    input.focus()
    input.value = '5551234567'
    input.dispatchEvent(new InputEvent('input', { bubbles: true, inputType: 'insertText' }))
    await settled()
    assert.strictEqual(model.phone, '(555) 123-4567')
    await a11yAudit()
  })
})
