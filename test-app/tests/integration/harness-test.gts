import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click } from '@ember/test-helpers'
import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { Form, type ControlSignature } from '@formwright/ember'
import {
  form,
  registerControlHarness,
  selectors,
  type FieldHarness,
} from '@formwright/test-support'

class Stepper extends Component<ControlSignature<number>> {
  inc = () => this.args.onChange((this.args.value ?? 0) + 1)
  <template>
    <output id={{@id}} data-test-stepper-value>{{@value}}</output>
    <button type="button" data-test-stepper-inc {{on "click" this.inc}}>+</button>
  </template>
}

module('Integration | test-support harness', function (hooks) {
  setupRenderingTest(hooks)

  test('it reads label, hint, required, dirty and invalid state', async function (assert) {
    const model = { email: '' }
    const validator = () => ({ email: ['Required'] })

    await render(
      <template>
        <Form @model={{model}} @name="signup" @validator={{validator}} as |f|>
          <f.Field @for="email" @label="Email" @hint="Work address" @required={{true}} />
        </Form>
      </template>,
    )

    const email = form('signup').field('email')
    assert.strictEqual(email.label, 'Email')
    assert.strictEqual(email.hint, 'Work address')
    assert.true(email.isRequired)
    assert.false(email.isDirty)
    await email.fillIn('x')
    assert.true(email.isDirty)
    await form('signup').submit()
    assert.true(email.isInvalid)
  })

  test('paths are normalized: items[0].name and items.0.name are the same field', async function (assert) {
    const model = { items: [{ name: 'a' }] }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="items[0].name" @label="First item" />
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-field="items.0.name"]').exists()
    assert.strictEqual(selectors.field('items[0].name'), '[data-test-fw-field="items.0.name"]')
    await form().field('items[0].name').fillIn('b')
    assert.strictEqual(model.items[0]!.name, 'b')
  })

  test('nested forms scope their fields: same path, different forms', async function (assert) {
    const user = { name: 'Ada', company: { name: 'Analytical Engines' } }

    await render(
      <template>
        <Form @model={{user}} @name="user" as |f|>
          <f.Field @for="name" @label="Your name" />
          <f.Form @model={{user.company}} @name="company" as |c|>
            <c.Field @for="name" @label="Company name" />
          </f.Form>
        </Form>
      </template>,
    )

    assert.strictEqual(form('user').field('name').label, 'Your name')
    assert.strictEqual(form('user').form('company').field('name').label, 'Company name')
    await form('user').form('company').field('name').fillIn('Babbage & Co')
    assert.strictEqual(user.company.name, 'Babbage & Co')
    assert.strictEqual(user.name, 'Ada')
  })

  test('custom controls can register a driver', async function (assert) {
    registerControlHarness('custom', {
      value: (field: FieldHarness) =>
        Number(field.element.querySelector('[data-test-stepper-value]')!.textContent),
    })
    const model = { count: 1 }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="count" @control={{Stepper}} @label="Count" />
        </Form>
      </template>,
    )

    await click('[data-test-stepper-inc]')
    assert.strictEqual(form().field('count').value, 2)
  })

  test('missing things fail with a clear message', async function (assert) {
    const model = { a: '' }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="a" @label="A" />
        </Form>
      </template>,
    )

    assert.throws(() => form('nope').element, /no form "nope" found/)
    assert.throws(() => form().field('b').element, /no field "b" found/)
    try {
      await form().field('a').select('x')
      assert.ok(false)
    } catch (e) {
      assert.true(String(e).includes(`can't select on a "input" control`))
    }
  })
})
