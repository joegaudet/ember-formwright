import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, field } from '@ember-formwright/test-support'
import { PhoneHarness } from '@ember-formwright/maskito/test-support'
import ContactForm, { createModel } from 'docs-app/examples/controls-phone'

class ContactHarness extends FormHarness {
  static formName = 'contact'
  @field(PhoneHarness) declare phone: PhoneHarness
  @field(PhoneHarness) declare mobile: PhoneHarness
  @field(PhoneHarness) declare office: PhoneHarness
}

module('Example | controls-phone', function (hooks) {
  setupRenderingTest(hooks)

  test('masks as you type, stores E.164, validates', async function (assert) {
    const model = createModel()
    await render(<template><ContactForm @model={{model}} /></template>)
    const contact = new ContactHarness()

    assert.strictEqual(contact.phone.value, '+1 212 555-0123', 'the stored number, formatted')

    await contact.mobile.fillIn('07700900123')
    assert.strictEqual(contact.mobile.value, '+44 7700 900123')
    assert.strictEqual(model.mobile, '+447700900123')

    await contact.office.fillIn('+33612')
    await contact.submit()
    assert.deepEqual(contact.office.errors, ['That number looks off'])

    await contact.office.fillIn('+33612345678')
    assert.strictEqual(model.office, '+33612345678')
    assert.deepEqual(contact.office.errors, [])
    await a11yAudit()
  })
})
