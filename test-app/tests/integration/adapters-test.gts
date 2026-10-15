import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { Form } from '@ember-formwright/ember'
import { TestForm } from 'test-app/tests/helpers/test-form'
import { warpDriveAdapter } from '@ember-formwright/warp-drive'
import { changesetAdapter, changesetValidator } from '@ember-formwright/changeset'
import { Changeset } from 'ember-changeset'
import { lookupValidator } from 'validated-changeset'
import { enumOptions, enumValue, enumLabel } from '@ember-formwright/real-enums'
import { registerMaskedControl } from '@ember-formwright/maskito'

/** Mirrors real-enums 2's Enum: a String subclass with `values`, `value` and `label`. */
class Enum extends String {
  readonly value: string
  constructor(value: string) {
    super(value)
    this.value = value
  }
  get id() {
    return this
  }
  get label() {
    return this.value.charAt(0).toUpperCase() + this.value.slice(1)
  }
  static get values(): any[] {
    return Object.values(this).filter(member => member instanceof this)
  }
}

class OrderState extends Enum {
  static Pending = new OrderState('pending')
  static Shipped = new OrderState('shipped')
  static Cancelled = new OrderState('cancelled')
}

/** Just enough of an ember-data record for the adapter's contract. */
class FakeRecord {
  @tracked name = 'Ada'
  @tracked hasDirtyAttributes = false
  isNew = false
  isDeleted = false
  saves = 0
  rollbacks = 0
  serverErrors: Record<string, string[]> = {}
  @tracked errorsVersion = 0

  errors = {
    errorsFor: (attribute: string) => {
      void this.errorsVersion
      return (this.serverErrors[attribute] ?? []).map(message => ({ message }))
    },
  }

  save() {
    this.saves++
    return Promise.resolve(this)
  }

  rollbackAttributes() {
    this.rollbacks++
    this.name = 'Ada'
  }

  failWith(errors: Record<string, string[]>) {
    this.serverErrors = errors
    this.errorsVersion++
  }
}

/** A model a changeset wraps: counts saves so tests can see when the buffer is applied. */
class Person {
  @tracked name = 'Ada'
  saves = 0

  save() {
    this.saves++
    return Promise.resolve(this)
  }
}

class Company {
  @tracked name = 'Acme'
  address = { city: 'Rotterdam' }
  saves = 0

  save() {
    this.saves++
    return Promise.resolve(this)
  }
}

const requireName = ({ key, newValue }: { key: string; newValue: unknown }) =>
  key !== 'name' || Boolean(newValue) || 'is required'

module('Integration | adapters', function (hooks) {
  setupRenderingTest(hooks)

  let ui: TestForm
  hooks.beforeEach(function () {
    ui = new TestForm()
  })

  test('warp-drive: save, rollback and server errors', async function (assert) {
    const record = new FakeRecord()

    await render(
      <template>
        <Form @model={{record}} @adapter={{warpDriveAdapter}} as |f|>
          <f.Errors />
          <f.Field @for="name" @label="Name" />
          <f.Reset />
        </Form>
      </template>,
    )

    await ui.name.fillIn('Grace')
    await ui.submit()
    assert.strictEqual(record.saves, 1, 'submit saves the record')

    await ui.name.fillIn('Hopper')
    await ui.reset()
    assert.strictEqual(record.rollbacks, 1, 'reset rolls the record back')
    assert.strictEqual(record.name, 'Ada')

    record.failWith({ name: ['is taken'], base: ['Try again later'] })
    await ui.name.fillIn('Ada L')
    assert.deepEqual(ui.name.errors, ['is taken'])
    assert.deepEqual(ui.errors, ['Try again later'])
  })

  test('warp-drive: a nested new record saves with its parent even when untouched', async function (assert) {
    const parent = new FakeRecord()
    const child = new FakeRecord()
    child.isNew = true

    await render(
      <template>
        <Form @model={{parent}} @adapter={{warpDriveAdapter}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Form @model={{child}} @name="child" as |c|>
            <c.Field @for="name" @label="Child name" />
          </f.Form>
        </Form>
      </template>,
    )

    await ui.submit()
    assert.strictEqual(parent.saves, 1)
    assert.strictEqual(
      child.saves,
      1,
      'nested forms inherit the adapter, and isNew means needsSave',
    )
  })

  test('changeset: edits stay in the changeset until submit', async function (assert) {
    const person = new Person()
    const cs = Changeset(person, requireName)

    await render(
      <template>
        <Form @model={{cs}} @adapter={{changesetAdapter}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    assert.strictEqual(ui.name.value, 'Ada', 'reads through the changeset')
    await ui.name.fillIn('Grace')
    assert.strictEqual(cs.get('name'), 'Grace')
    assert.strictEqual(person.name, 'Ada', 'the model is untouched while editing')

    await ui.submit()
    assert.strictEqual(person.name, 'Grace', 'submit applies the changes')
    assert.strictEqual(person.saves, 1, 'and saves the model once')
    assert.false(cs.isDirty)
  })

  test('changeset: reset discards the changes', async function (assert) {
    const person = new Person()
    const cs = Changeset(person)

    await render(
      <template>
        <Form @model={{cs}} @adapter={{changesetAdapter}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Reset />
        </Form>
      </template>,
    )

    await ui.name.fillIn('Grace')
    await ui.reset()
    assert.strictEqual(ui.name.value, 'Ada')
    assert.false(cs.isDirty, 'the changeset is rolled back')
    assert.strictEqual(person.name, 'Ada', 'the model never changed')
    assert.strictEqual(person.saves, 0)
  })

  test('changeset: validations block submit and show on their fields', async function (assert) {
    const person = new Person()
    const cs = Changeset(person, requireName)

    await render(
      <template>
        <Form @model={{cs}} @adapter={{changesetAdapter}} @validator={{changesetValidator}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    await ui.name.fillIn('')
    await ui.submit()
    assert.strictEqual(person.saves, 0, 'an invalid changeset is not saved')
    assert.deepEqual(ui.name.errors, ['is required'])

    await ui.name.fillIn('Grace')
    assert.deepEqual(ui.name.errors, [], 'errors clear once the value is valid')
    await ui.submit()
    assert.strictEqual(person.saves, 1)
    assert.strictEqual(person.name, 'Grace')
  })

  test('changeset: the adapter refuses to save an invalid changeset', async function (assert) {
    const person = new Person()
    const cs = Changeset(person, requireName)
    cs.set('name', '')

    await assert.rejects(Promise.resolve().then(() => changesetAdapter.save!(cs)))
    assert.strictEqual(person.saves, 0, 'the stale model is not saved')
  })

  test('changeset: a failed save leaves the model as it was', async function (assert) {
    const person = new Person()
    person.save = () => Promise.reject(new Error('422'))
    const cs = Changeset(person)
    const failed: unknown[] = []
    const failedSubmit = (error: unknown) => failed.push(error)

    await render(
      <template>
        <Form @model={{cs}} @adapter={{changesetAdapter}} @failedSubmit={{failedSubmit}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Reset />
        </Form>
      </template>,
    )

    await ui.name.fillIn('Grace')
    await ui.submit()
    assert.strictEqual(failed.length, 1)
    assert.strictEqual(person.name, 'Ada', 'the unsaved edit is taken back off the model')
    assert.strictEqual(ui.name.value, 'Grace', 'and stays in the changeset to retry')

    await ui.reset()
    assert.strictEqual(ui.name.value, 'Ada')
    assert.strictEqual(person.name, 'Ada')
  })

  test('changeset: a validation map checks fields nobody touched', async function (assert) {
    const person = new Person()
    person.name = ''
    const validations = { name: (_key: string, value: unknown) => Boolean(value) || 'is required' }
    const cs = Changeset(person, lookupValidator(validations), validations)

    await render(
      <template>
        <Form @model={{cs}} @adapter={{changesetAdapter}} @validator={{changesetValidator}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    await ui.submit()
    assert.strictEqual(person.saves, 0)
    assert.deepEqual(ui.name.errors, ['is required'])
  })

  test('changeset: a nested form over part of the changeset edits through it', async function (assert) {
    const company = new Company()
    const cs = Changeset(company)

    await render(
      <template>
        <Form @model={{cs}} @adapter={{changesetAdapter}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Form @model={{cs.address}} @name="address" as |a|>
            <a.Field @for="city" @label="City" />
          </f.Form>
          <f.Reset />
        </Form>
      </template>,
    )

    assert.strictEqual(ui.address.city.value, 'Rotterdam', 'reads the model through the changeset')
    await ui.address.city.fillIn('Delft')
    assert.strictEqual(company.address.city, 'Rotterdam', 'the model is untouched while editing')

    await ui.submit()
    assert.strictEqual(company.address.city, 'Delft', 'the parent changeset saves the nested edit')
    assert.strictEqual(company.saves, 1)
  })

  test('changeset: a nested form saves its dirty changeset with the parent', async function (assert) {
    const parent = Changeset(new Person())
    const child = new Person()
    const childCs = Changeset(child)

    await render(
      <template>
        <Form @model={{parent}} @adapter={{changesetAdapter}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Form @model={{childCs}} @name="child" as |c|>
            <c.Field @for="name" @label="Child name" />
          </f.Form>
        </Form>
      </template>,
    )

    childCs.set('name', 'Grace')
    await ui.submit()
    assert.strictEqual(child.name, 'Grace')
    assert.strictEqual(child.saves, 1, 'isDirty means needsSave')
  })

  test('real-enums: members as options, stored as members or raw values', async function (assert) {
    const order: { state: unknown; raw: string } = { state: OrderState.Pending, raw: 'pending' }

    await render(
      <template>
        <Form @model={{order}} as |f|>
          <f.Field
            @for="state"
            @control="select"
            @label="State"
            @options={{enumOptions OrderState}}
          />
          <f.Field
            @for="raw"
            @control="radio"
            @label="Raw state"
            @options={{enumOptions OrderState except=(array OrderState.Cancelled)}}
            @optionKey={{enumValue}}
            @storeKey={{true}}
          />
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-field="state"] option:checked').hasText('Pending')
    await ui.state.select('shipped')
    assert.strictEqual(order.state, OrderState.Shipped, 'stores the enum member')

    assert.dom('[data-test-fw-field="raw"] [data-test-fw-option]').exists({ count: 2 })
    assert.strictEqual(ui.raw.value, 'pending')
    await ui.raw.select('shipped')
    assert.strictEqual(order.raw, 'shipped', 'stores the raw string')
  })

  test('real-enums: enumLabel formats inline values', async function (assert) {
    const order = { raw: 'shipped' }
    const format = enumLabel(OrderState)

    await render(
      <template>
        <Form @model={{order}} @inline={{true}} as |f|>
          <f.Field @for="raw" @label="State" @format={{format}} />
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-display]').hasText('Shipped')
  })

  test('maskito: a registered masked control formats as you type', async function (assert) {
    registerMaskedControl()
    const model = { code: '' }
    const mask = { mask: [/\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/] }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="code" @control="masked" @label="Code" as |field|>
            <field.Control @mask={{mask}} />
          </f.Field>
        </Form>
      </template>,
    )

    const input = document.querySelector<HTMLInputElement>('[data-test-fw-field="code"] input')!
    input.focus()
    input.value = '123456'
    input.dispatchEvent(new InputEvent('input', { bubbles: true, inputType: 'insertText' }))
    await new Promise(r => setTimeout(r, 20))
    assert.strictEqual(input.value, '123-456', 'maskito rewrites the value')
    assert.strictEqual(model.code, '123-456')
  })
})
