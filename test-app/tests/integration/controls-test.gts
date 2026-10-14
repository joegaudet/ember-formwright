import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, blur } from '@ember/test-helpers'
import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { get } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, registerControl, lookupControl, type ControlSignature } from '@formwright/ember'
import { form } from '@formwright/test-support'

const SIZES = [
  { id: 's', label: 'Small' },
  { id: 'm', label: 'Medium' },
  { id: 'l', label: 'Large', disabled: true },
]

module('Integration | controls', function (hooks) {
  setupRenderingTest(hooks)

  test('input types map to native inputs', async function (assert) {
    const model = {}
    const types = [
      ['email', 'email'],
      ['password', 'password'],
      ['search', 'search'],
      ['tel', 'tel'],
      ['url', 'url'],
      ['color', 'color'],
      ['date', 'date'],
      ['datetime', 'datetime-local'],
      ['time', 'time'],
      ['range', 'range'],
      ['number', 'number'],
    ]

    await render(
      <template>
        <Form @model={{model}} as |f|>
          {{#each types as |t|}}
            <f.Field @for={{get t 0}} @control={{get t 0}} @label={{get t 0}} />
          {{/each}}
        </Form>
      </template>,
    )

    for (const [control, type] of types) {
      assert.dom(`[data-test-fw-field="${control}"] input`).hasAttribute('type', type!)
      assert.dom(`[data-test-fw-field="${control}"]`).hasAttribute('data-test-fw-type', control!)
    }
  })

  test('number stores numbers, empty stores null', async function (assert) {
    const model: { qty: number | null } = { qty: 1 }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="qty" @control="number" @label="Qty" />
        </Form>
      </template>,
    )

    await form().field('qty').fillIn('42')
    assert.strictEqual(model.qty, 42)
    await form().field('qty').fillIn('')
    assert.strictEqual(model.qty, null)
  })

  test('select: objects, placeholder, disabled options and unknown values', async function (assert) {
    const model: { size: unknown } = { size: undefined }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field
            @for="size"
            @control="select"
            @label="Size"
            @options={{SIZES}}
            @placeholder="Pick a size"
          />
        </Form>
      </template>,
    )

    assert.dom('select option:checked').hasText('Pick a size')
    assert.dom('[data-test-fw-option="l"]').isDisabled()

    await form().field('size').select('m')
    assert.strictEqual(model.size, SIZES[1], 'stores the option object by default')
    assert.strictEqual(form().field('size').value, 'm')
  })

  test('select: @storeKey stores the key, and primitives work', async function (assert) {
    const model = { size: 's', color: 'red' }
    const colors = ['red', 'green']

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field
            @for="size"
            @control="select"
            @label="Size"
            @options={{SIZES}}
            @storeKey={{true}}
          />
          <f.Field @for="color" @control="select" @label="Color" @options={{colors}} />
        </Form>
      </template>,
    )

    assert.strictEqual(form().field('size').value, 's', 'selects the stored key on first render')
    await form().field('size').select('m')
    assert.strictEqual(model.size, 'm')
    await form().field('color').select('green')
    assert.strictEqual(model.color, 'green')
  })

  test('select: a value missing from the options still shows', async function (assert) {
    const model = { color: 'blue' }
    const colors = ['red', 'green']

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="color" @control="select" @label="Color" @options={{colors}} />
        </Form>
      </template>,
    )

    assert.dom('select option:checked').hasText('blue')
  })

  test('radio group', async function (assert) {
    const model = { size: 's' }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field
            @for="size"
            @control="radio"
            @label="Size"
            @options={{SIZES}}
            @storeKey={{true}}
          />
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-field="size"] fieldset legend').hasText('Size')
    assert.strictEqual(form().field('size').value, 's')
    await form().field('size').select('m')
    assert.strictEqual(model.size, 'm')
    await a11yAudit()
    assert.ok(true)
  })

  test('checkbox', async function (assert) {
    const model = { agree: false }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="agree" @control="checkbox" @label="I agree" />
        </Form>
      </template>,
    )

    await form().field('agree').check()
    assert.true(model.agree)
    assert.true(form().field('agree').value)
    await form().field('agree').uncheck()
    assert.false(model.agree)
  })

  test('checkbox group with a selection max', async function (assert) {
    const model: { sizes: string[] } = { sizes: [] }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field
            @for="sizes"
            @control="checkbox-group"
            @label="Sizes"
            @options={{SIZES}}
            @storeKey={{true}}
            @max={{1}}
          />
        </Form>
      </template>,
    )

    await form().field('sizes').select(['s'])
    assert.deepEqual(model.sizes, ['s'])
    assert.dom('[data-test-fw-option="m"]').isDisabled('at max, unchecked options disable')
    await click('[data-test-fw-option="s"]')
    assert.deepEqual(model.sizes, [])
    assert.deepEqual(form().field('sizes').value, [])
  })

  test('textarea', async function (assert) {
    const model = { bio: 'hi' }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="bio" @control="textarea" @label="Bio" />
        </Form>
      </template>,
    )

    assert.strictEqual(form().field('bio').value, 'hi')
    await form().field('bio').fillIn('hello')
    assert.strictEqual(model.bio, 'hello')
  })

  test('currency parses and formats with Intl', async function (assert) {
    const model: { price: number | null } = { price: 1234.5 }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="price" @control="currency" @label="Price" as |field|>
            <field.Control @currency="EUR" @locale="de-DE" />
          </f.Field>
        </Form>
      </template>,
    )

    const input = '[data-test-fw-field="price"] input'
    // Intl puts a no-break space before the symbol.
    const shown = () => document.querySelector<HTMLInputElement>(input)!.value.replace(/\s/g, ' ')
    assert.strictEqual(shown(), '1.234,50 €')
    await form().field('price').fillIn('99,9')
    assert.strictEqual(model.price, 99.9)
    await blur(input)
    assert.strictEqual(shown(), '99,90 €')
    await form().field('price').fillIn('')
    assert.strictEqual(model.price, null)
  })

  test('custom controls: pass a component, or register one by name', async function (assert) {
    class Stepper extends Component<ControlSignature<number>> {
      inc = () => this.args.onChange((this.args.value ?? 0) + 1)
      <template>
        <button
          id={{@id}}
          type="button"
          data-test-stepper
          {{on "click" this.inc}}
        >{{@value}}</button>
      </template>
    }
    registerControl('stepper', Stepper)
    const model = { a: 1, b: 5 }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="a" @control={{Stepper}} @label="A" />
          <f.Field @for="b" @control="stepper" @label="B" />
        </Form>
      </template>,
    )

    await click('[data-test-fw-field="a"] [data-test-stepper]')
    await click('[data-test-fw-field="b"] [data-test-stepper]')
    assert.deepEqual(model, { a: 2, b: 6 })
  })

  test('an unknown control name throws a helpful error', function (assert) {
    assert.throws(() => lookupControl('nope'), /Unknown Formwright control "nope"/)
  })
})
