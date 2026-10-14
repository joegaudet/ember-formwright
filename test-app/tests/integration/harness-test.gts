import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click } from '@ember/test-helpers'
import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { Form, type ControlSignature } from '@formwright/ember'
import {
  FormHarness,
  FieldHarness,
  InputHarness,
  SelectHarness,
  CheckboxGroupHarness,
  field,
  form,
  selectors,
} from '@formwright/test-support'

class Stepper extends Component<ControlSignature<number>> {
  inc = () => this.args.onChange((this.args.value ?? 0) + 1)
  <template>
    <output id={{@id}} data-test-stepper-value>{{@value}}</output>
    <button type="button" data-test-stepper-inc {{on "click" this.inc}}>+</button>
  </template>
}

/** A custom control gets its harness by subclassing FieldHarness. */
class StepperHarness extends FieldHarness {
  get value(): number {
    return Number(this.element.querySelector('[data-test-stepper-value]')!.textContent)
  }

  async increment(): Promise<void> {
    await click(this.element.querySelector('[data-test-stepper-inc]')!)
  }
}

class CompanyForm extends FormHarness {
  @field(InputHarness) declare name: InputHarness
}

class UserForm extends FormHarness {
  static formName = 'user'

  @field(InputHarness) declare name: InputHarness
  @field(InputHarness, 'email') declare emailAddress: InputHarness
  @field(SelectHarness) declare plan: SelectHarness
  @field(CheckboxGroupHarness) declare notify: CheckboxGroupHarness
  @field(StepperHarness) declare seats: StepperHarness
  @form(CompanyForm) declare company: CompanyForm
}

const PLANS = ['hobby', 'team']
const CHANNELS = ['email', 'sms']

module('Integration | test-support harness', function (hooks) {
  setupRenderingTest(hooks)

  test('form classes declare their fields and nested forms with decorators', async function (assert) {
    const user = {
      name: 'Ada',
      email: '',
      plan: 'hobby',
      notify: [] as string[],
      seats: 1,
      company: { name: 'Analytical Engines' },
    }

    await render(
      <template>
        <Form @model={{user}} @name="user" as |f|>
          <f.Field @for="name" @label="Your name" />
          <f.Field @for="email" @control="email" @label="Email" />
          <f.Field @for="plan" @control="select" @label="Plan" @options={{PLANS}} />
          <f.Field @for="notify" @control="checkbox-group" @label="Notify" @options={{CHANNELS}} />
          <f.Field @for="seats" @control={{Stepper}} @label="Seats" />
          <f.Form @model={{user.company}} @name="company" as |c|>
            <c.Field @for="name" @label="Company name" />
          </f.Form>
        </Form>
      </template>,
    )

    const harness = new UserForm()
    await harness.emailAddress.fillIn('ada@example.com')
    await harness.plan.select('team')
    await harness.notify.select(['email', 'sms'])
    await harness.seats.increment()
    await harness.company.name.fillIn('Babbage & Co')

    assert.strictEqual(
      user.email,
      'ada@example.com',
      'the path argument overrides the property name',
    )
    assert.strictEqual(user.plan, 'team')
    assert.deepEqual(user.notify, ['email', 'sms'])
    assert.strictEqual(harness.seats.value, 2, 'subclasses add their own reads and actions')
    assert.strictEqual(user.company.name, 'Babbage & Co')
    assert.strictEqual(harness.name.label, 'Your name', 'nested forms scope same-named fields')
    assert.strictEqual(harness.company.name.label, 'Company name')
  })

  test('harnesses are created once and stay valid across re-renders', async function (assert) {
    const user = { name: 'Ada', company: { name: 'x' } }

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

    const harness = new UserForm()
    assert.strictEqual(
      harness.name,
      harness.name,
      'a decorated field is the same instance on every read',
    )
    assert.strictEqual(harness.company, harness.company)
    assert.strictEqual(harness.field('name', InputHarness), harness.field('name', InputHarness))

    await harness.name.fillIn('Grace')
    assert.strictEqual(harness.name.value, 'Grace', 'the element is looked up live')
  })

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

    const email = new FormHarness('signup').field('email', InputHarness)
    assert.strictEqual(email.label, 'Email')
    assert.strictEqual(email.hint, 'Work address')
    assert.true(email.isRequired)
    assert.false(email.isDirty)
    await email.fillIn('x')
    assert.true(email.isDirty)
    await new FormHarness('signup').submit()
    assert.true(email.isInvalid)
    assert.deepEqual(email.errors, ['Required'])
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
    await new FormHarness().field('items[0].name', InputHarness).fillIn('b')
    assert.strictEqual(model.items[0]!.name, 'b')
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

    assert.throws(() => new FormHarness('nope').element, /no form "nope" found/)
    assert.throws(() => new FormHarness().field('b', InputHarness).element, /no field "b" found/)
    assert.throws(
      () => new FormHarness().field('a', SelectHarness).value,
      /field "a" is a "input" control; this harness drives select/,
    )
  })
})
