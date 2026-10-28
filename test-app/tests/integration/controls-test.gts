import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, blur } from '@ember/test-helpers'
import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { on } from '@ember/modifier'
import { get } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  Form,
  registerControl,
  lookupControl,
  type ControlSignature,
} from '@ember-formwright/ember'
import { TestForm } from 'test-app/tests/helpers/test-form'

const SIZES = [
  { id: 's', label: 'Small' },
  { id: 'm', label: 'Medium' },
  { id: 'l', label: 'Large', disabled: true },
]

module('Integration | controls', function (hooks) {
  setupRenderingTest(hooks)

  let ui: TestForm
  hooks.beforeEach(function () {
    ui = new TestForm()
  })

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

    await ui.qty.fillIn('42')
    assert.strictEqual(model.qty, 42)
    await ui.qty.fillIn('')
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

    await ui.size.select('m')
    assert.strictEqual(model.size, SIZES[1], 'stores the option object by default')
    assert.strictEqual(ui.size.value, 'm')
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

    assert.strictEqual(ui.size.value, 's', 'selects the stored key on first render')
    await ui.size.select('m')
    assert.strictEqual(model.size, 'm')
    await ui.color.select('green')
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
    assert.strictEqual(ui.sizeRadio.value, 's')
    await ui.sizeRadio.select('m')
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

    await ui.agree.check()
    assert.true(model.agree)
    assert.true(ui.agree.value)
    await ui.agree.uncheck()
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

    await ui.sizes.select(['s'])
    assert.deepEqual(model.sizes, ['s'])
    assert.dom('[data-test-fw-option="m"]').isDisabled('at max, unchecked options disable')
    await click('[data-test-fw-option="s"]')
    assert.deepEqual(model.sizes, [])
    assert.deepEqual(ui.sizes.value, [])
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

    assert.strictEqual(ui.bio.value, 'hi')
    await ui.bio.fillIn('hello')
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
    await ui.price.fillIn('99,9')
    assert.strictEqual(model.price, 99.9)
    await blur(input)
    assert.strictEqual(shown(), '99,90 €')
    await ui.price.fillIn('')
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

  test('inline and confirm modes focus a control whose focusable element is not an input', async function (assert) {
    // A listbox-like control: the field's id is on a div with a tabindex, and a native
    // input that is not the control comes first.
    const Picker: TOC<ControlSignature<string>> = <template>
      <input type="hidden" value={{@value}} />
      <div id={{@id}} role="combobox" aria-expanded="false" tabindex="0" data-test-picker>
        {{@value}}
      </div>
    </template>
    const model = { a: 'x', b: 'y' }

    await render(
      <template>
        <Form @model={{model}} @inline={{true}} as |f|>
          <f.Field @for="a" @control={{Picker}} @label="A" />
        </Form>
        <Form @model={{model}} @inline={{true}} @callout={{true}} @name="callout" as |f|>
          <f.Field @for="b" @control={{Picker}} @label="B" />
        </Form>
      </template>,
    )

    await click('[data-test-fw-field="a"] [data-test-fw-display]')
    assert.dom('[data-test-fw-field="a"] [data-test-picker]').isFocused()
    await click('[data-test-fw-field="b"] [data-test-fw-display]')
    assert.dom('[data-test-fw-field="b"] [data-test-picker]').isFocused()
  })

  test('a control is told when it renders inside a callout', async function (assert) {
    const Where: TOC<ControlSignature<string>> = <template>
      <input id={{@id}} data-test-where={{if @callout "callout" "inline"}} />
    </template>
    const model = { a: '', b: '' }

    await render(
      <template>
        <Form @model={{model}} @inline={{true}} as |f|>
          <f.Field @for="a" @control={{Where}} @label="A" />
        </Form>
        <Form @model={{model}} @inline={{true}} @callout={{true}} @name="callout" as |f|>
          <f.Field @for="b" @control={{Where}} @label="B" />
        </Form>
      </template>,
    )

    await click('[data-test-fw-field="a"] [data-test-fw-display]')
    await click('[data-test-fw-field="b"] [data-test-fw-display]')
    assert
      .dom('[data-test-fw-field="a"] [data-test-where]')
      .hasAttribute('data-test-where', 'inline')
    assert
      .dom('[data-test-fw-field="b"] [data-test-where]')
      .hasAttribute('data-test-where', 'callout')
  })

  test('an unknown control name throws a helpful error', function (assert) {
    assert.throws(() => lookupControl('nope'), /Unknown Formwright control "nope"/)
  })
})
