import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  Form,
  registerLayout,
  setDefaultLayout,
  type FieldLayoutSignature,
} from '@ember-formwright/ember'
import { TestForm } from 'test-app/tests/helpers/test-form'

/** The label after the control, wrapped: a structural change CSS alone can't make. */
const LabelLast: TOC<FieldLayoutSignature> = <template>
  <@parts.Group>
    <div class="label-last" data-test-layout="label-last">
      <@parts.Control as |control|>{{yield control}}</@parts.Control>
      <@parts.Label />
    </div>
    <@parts.Hint />
    <@parts.Errors />
  </@parts.Group>
</template>

/** Shows the read-only state a layout receives. */
const Stateful: TOC<FieldLayoutSignature> = <template>
  <span
    data-test-state
    data-id={{@field.id}}
    data-control={{@field.controlName}}
    data-group={{if @field.isGroup "yes" "no"}}
    data-required={{if @field.required "yes" "no"}}
    data-disabled={{if @field.disabled "yes" "no"}}
  ></span>
  <@parts.Label class="extra-class" />
  <@parts.Control as |control|>{{yield control}}</@parts.Control>
</template>

/** Forgets to pass the field's block on. */
const Careless: TOC<FieldLayoutSignature> = <template>
  <@parts.Label />
  <@parts.Control />
</template>

const SIZES = [
  { id: 's', label: 'Small' },
  { id: 'm', label: 'Medium' },
]

module('Integration | layouts', function (hooks) {
  setupRenderingTest(hooks)

  let ui: TestForm
  hooks.beforeEach(function () {
    ui = new TestForm()
  })
  hooks.afterEach(function () {
    setDefaultLayout('default')
  })

  test('a Form @layout component arranges its fields; the outer element stays the core’s', async function (assert) {
    const model = { name: 'Ada' }

    await render(
      <template>
        <Form @model={{model}} @layout={{LabelLast}} as |f|>
          <f.Field @for="name" @label="Name" @hint="Your name" class="mine" />
        </Form>
      </template>,
    )

    const field = '[data-test-fw-field="name"]'
    assert.dom(field).hasClass('fw-field').hasClass('mine')
    assert.dom(`${field} > .label-last > .fw-control-area + label.fw-label`).exists()
    assert.dom(`${field} > .label-last + .fw-hint`).hasText('Your name')
    assert.dom(`${field} input`).hasAttribute('aria-describedby', `${ui.name.control.id}-hint`)
    assert.strictEqual(ui.name.label, 'Name')
    await ui.name.fillIn('Grace')
    assert.strictEqual(model.name, 'Grace')
  })

  test('layouts register by name; nested forms inherit, and a field overrides', async function (assert) {
    registerLayout('label-last', LabelLast)
    const model = { name: 'Ada', email: '', address: { city: '' } }

    await render(
      <template>
        <Form @model={{model}} @layout="label-last" as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Field @for="email" @label="Email" @layout="default" />
          <f.Form @model={{model.address}} @name="address" as |a|>
            <a.Field @for="city" @label="City" />
          </f.Form>
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-field="name"] [data-test-layout]').exists()
    assert.dom('[data-test-fw-field="email"] [data-test-layout]').doesNotExist()
    assert.dom('[data-test-fw-field="email"] > label.fw-label').exists('the default layout')
    assert
      .dom('[data-test-fw-field="city"] [data-test-layout]')
      .exists('inherited by a nested form')
  })

  test('setDefaultLayout changes every form without its own @layout', async function (assert) {
    setDefaultLayout(LabelLast)
    const model = { name: '' }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-field="name"] [data-test-layout]').exists()
  })

  test('an unknown layout name throws a helpful error', async function (assert) {
    setDefaultLayout('default')
    assert.throws(() => setDefaultLayout('nope'), /Unknown Formwright layout "nope"/)
  })

  test('a layout gets read-only field state, and parts take attributes', async function (assert) {
    const model = { size: 's' }

    await render(
      <template>
        <Form @model={{model}} @disabled={{true}} @layout={{Stateful}} as |f|>
          <f.Field
            @for="size"
            @control="radio"
            @label="Size"
            @options={{SIZES}}
            @storeKey={{true}}
            @required={{true}}
          />
        </Form>
      </template>,
    )

    const id = document.querySelector('[data-test-fw-field="size"] input')!.id
    assert
      .dom('[data-test-state]')
      .hasAttribute('data-id', id)
      .hasAttribute('data-control', 'radio')
      .hasAttribute('data-group', 'yes')
      .hasAttribute('data-required', 'yes')
      .hasAttribute('data-disabled', 'yes')
    assert.dom('legend.fw-label').hasClass('extra-class')
  })

  test('a field’s block still replaces only the control', async function (assert) {
    const model = { bio: '' }

    await render(
      <template>
        <Form @model={{model}} @layout={{LabelLast}} as |f|>
          <f.Field @for="bio" @control="textarea" @label="Bio" as |field|>
            <div data-test-wrap><field.Control @maxLength={{20}} /></div>
          </f.Field>
        </Form>
      </template>,
    )

    assert.dom('.label-last > .fw-control-area > [data-test-wrap] textarea').exists()
    assert.dom('.label-last > .fw-control-area + label').hasText('Bio')
  })

  test('a layout that drops a field’s block still renders the control', async function (assert) {
    const model = { bio: '' }

    await render(
      <template>
        <Form @model={{model}} @layout={{Careless}} as |f|>
          <f.Field @for="bio" @label="Bio" as |field|>
            <div data-test-wrap><field.Control /></div>
          </f.Field>
        </Form>
      </template>,
    )

    assert.dom('[data-test-wrap]').doesNotExist('the block needs the layout to pass it on')
    await ui.bio.fillIn('Hi')
    assert.strictEqual(model.bio, 'Hi')
  })

  test('the default layout with a group control: the legend is the fieldset’s first child', async function (assert) {
    const model = { size: 's', sizes: [] }

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
          <f.Field
            @for="sizes"
            @control="checkbox-group"
            @label="Sizes"
            @hint="Any"
            @options={{SIZES}}
            @storeKey={{true}}
          />
        </Form>
      </template>,
    )

    for (const fieldset of document.querySelectorAll('fieldset.fw-group')) {
      assert.strictEqual(fieldset.firstElementChild?.tagName, 'LEGEND')
    }
    await a11yAudit()
  })
})
