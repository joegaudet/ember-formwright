import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled, triggerKeyEvent } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { z } from 'zod'
import { Form } from '@ember-formwright/ember'
import { FormHarness, field } from '@ember-formwright/test-support'
import { formatPhone, isValidPhone, registerPhoneControl } from '@ember-formwright/maskito/phone'
import { PhoneHarness } from '@ember-formwright/maskito/test-support'

registerPhoneControl()

class Contact {
  @tracked phone: string | null = null
  @tracked mobile: string | null = null
}

class ContactForm extends FormHarness {
  @field(PhoneHarness) declare phone: PhoneHarness
  @field(PhoneHarness) declare mobile: PhoneHarness
}

const schema = z.object({
  phone: z
    .string()
    .nullable()
    .refine(v => isValidPhone(v), 'That number looks off'),
})

module('Integration | phone', function (hooks) {
  setupRenderingTest(hooks)

  let ui: ContactForm
  hooks.beforeEach(function () {
    ui = new ContactForm()
  })

  test('masks what is typed and stores E.164, with the field wired to the input', async function (assert) {
    const contact = new Contact()
    await render(
      <template>
        <Form @model={{contact}} as |f|>
          <f.Field
            @for="phone"
            @control="phone"
            @label="Phone"
            @hint="Mobile or landline"
            @required={{true}}
          />
        </Form>
      </template>,
    )

    const input = ui.phone.input
    assert.dom('[data-test-fw-field="phone"] label').hasAttribute('for', input.id)
    assert
      .dom(input)
      .hasAttribute('type', 'tel')
      .hasAttribute('autocomplete', 'tel')
      .hasAttribute('inputmode', 'tel')
      .hasAttribute('data-test-fw-control', 'phone')
      .hasAttribute('aria-describedby', `${input.id}-hint`)
      .isRequired()
      .hasValue('')

    await ui.phone.fillIn('2125550123')
    assert.strictEqual(ui.phone.value, '+1 212 555-0123')
    assert.strictEqual(contact.phone, '+12125550123')

    await ui.phone.fillIn('212555')
    assert.strictEqual(ui.phone.value, '+1 212 555')
    assert.strictEqual(contact.phone, '+1212555', 'partial input stores its digits')

    await ui.phone.clear()
    assert.strictEqual(contact.phone, null, 'empty stores null')
    await a11yAudit()
  })

  test('a stored number shows formatted, and @country picks the mask', async function (assert) {
    const contact = new Contact()
    contact.phone = '+12125550123'
    contact.mobile = '+447911123456'
    await render(
      <template>
        <Form @model={{contact}} as |f|>
          <f.Field @for="phone" @control="phone" @label="Phone" />
          <f.Field @for="mobile" @control="phone" @label="Mobile" as |field|>
            <field.Control @country="GB" />
          </f.Field>
        </Form>
      </template>,
    )

    assert.strictEqual(ui.phone.value, '+1 212 555-0123')
    assert.strictEqual(ui.mobile.value, '+44 7911 123456')

    await ui.mobile.fillIn('07700900123')
    assert.strictEqual(contact.mobile, '+447700900123', 'a national 0 is dropped')
    assert.strictEqual(ui.mobile.value, '+44 7700 900123')

    contact.phone = '+13125550199'
    await settled()
    assert.strictEqual(ui.phone.value, '+1 312 555-0199', 'follows a model change')
  })

  test('@national shows the national format and still stores E.164; @strict={{false}} takes any country', async function (assert) {
    const contact = new Contact()
    contact.phone = '+12125550123'
    await render(
      <template>
        <Form @model={{contact}} as |f|>
          <f.Field @for="phone" @control="phone" @label="Phone" as |field|>
            <field.Control @national={{true}} />
          </f.Field>
          <f.Field @for="mobile" @control="phone" @label="Mobile" as |field|>
            <field.Control @strict={{false}} />
          </f.Field>
        </Form>
      </template>,
    )

    assert.strictEqual(ui.phone.value, '(212) 555-0123')
    await ui.phone.fillIn('3125550199')
    assert.strictEqual(ui.phone.value, '(312) 555-0199')
    assert.strictEqual(contact.phone, '+13125550199')

    await ui.mobile.fillIn('+33612345678')
    assert.strictEqual(contact.mobile, '+33612345678')
    assert.strictEqual(ui.mobile.value, '+33 6 12-34-56-78')
  })

  test('isValidPhone in a validator marks a bad number invalid', async function (assert) {
    const contact = new Contact()
    await render(
      <template>
        <Form @model={{contact}} @validator={{schema}} as |f|>
          <f.Field @for="phone" @control="phone" @label="Phone" />
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )

    await ui.phone.fillIn('212')
    await ui.submit()
    assert.deepEqual(ui.phone.errors, ['That number looks off'])
    assert.dom(ui.phone.input).hasAttribute('aria-invalid', 'true')

    await ui.phone.fillIn('2125550123')
    assert.deepEqual(ui.phone.errors, [])
    await a11yAudit()

    assert.true(isValidPhone('+12125550123'))
    assert.false(isValidPhone('+1212'))
    assert.false(isValidPhone(null))
    assert.true(isValidPhone('2125550123', 'US'), 'reads a national number as the country given')
  })

  test('disabled and readonly reach the input; reset restores the stored number', async function (assert) {
    const contact = new Contact()
    contact.phone = '+12125550123'
    await render(
      <template>
        <Form @model={{contact}} as |f|>
          <f.Field @for="phone" @control="phone" @label="Phone" @disabled={{true}} />
          <f.Field @for="mobile" @control="phone" @label="Mobile" @readonly={{true}} />
        </Form>
      </template>,
    )
    assert.dom(ui.phone.input).isDisabled()
    assert.dom(ui.mobile.input).hasAttribute('readonly')

    await render(
      <template>
        <Form @model={{contact}} as |f|>
          <f.Field @for="phone" @control="phone" @label="Phone" />
          <f.Reset>Reset</f.Reset>
        </Form>
      </template>,
    )
    await ui.phone.fillIn('3125550199')
    assert.strictEqual(contact.phone, '+13125550199')
    await ui.reset()
    assert.strictEqual(contact.phone, '+12125550123')
    assert.strictEqual(ui.phone.value, '+1 212 555-0123')
  })

  test('inline mode shows formatPhone, and @requireConfirm waits for the commit', async function (assert) {
    const contact = new Contact()
    contact.phone = '+447911123456'
    contact.mobile = '+12125550123'
    await render(
      <template>
        <Form @model={{contact}} @inline={{true}} as |f|>
          <f.Field @for="phone" @control="phone" @label="Phone" @format={{formatPhone}} />
        </Form>
        <Form @model={{contact}} @name="confirm" @requireConfirm={{true}} as |f|>
          <f.Field @for="mobile" @control="phone" @label="Mobile" />
        </Form>
      </template>,
    )

    assert.strictEqual(ui.phone.displayText, '+44 7911 123456')
    await ui.phone.edit()
    assert.dom(ui.phone.input).isFocused()

    const confirm = new ContactForm('confirm')
    await confirm.mobile.fillIn('3125550199')
    assert.strictEqual(contact.mobile, '+12125550123', 'waits for the commit')
    assert.strictEqual(confirm.mobile.value, '+1 312 555-0199')
    await triggerKeyEvent(confirm.mobile.input, 'keydown', 'Enter')
    assert.strictEqual(contact.mobile, '+13125550199')

    assert.strictEqual(formatPhone(null), '')
    assert.strictEqual(formatPhone('not a number'), 'not a number')
  })
})
