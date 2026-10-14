import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { array } from '@ember/helper'
import { Form } from '@formwright/ember'
import { TestForm } from 'test-app/tests/helpers/test-form'
import { warpDriveAdapter } from '@formwright/warp-drive'
import { enumOptions, enumValue, enumLabel } from '@formwright/real-enums'
import { registerMaskedControl } from '@formwright/maskito'

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
