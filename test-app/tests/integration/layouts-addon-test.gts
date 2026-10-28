import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form } from '@ember-formwright/ember'
import {
  registerLayouts,
  Actions,
  Horizontal,
  Compact,
  CheckboxAfter,
} from '@ember-formwright/layouts'
import { TestForm } from 'test-app/tests/helpers/test-form'

registerLayouts()

const SIZES = [
  { id: 's', label: 'Small' },
  { id: 'm', label: 'Medium' },
]
const LAYOUTS = ['horizontal', 'compact', 'checkbox-after'] as const
const GROUPS = ['radio', 'checkbox-group'] as const

module('Integration | @ember-formwright/layouts', function (hooks) {
  setupRenderingTest(hooks)

  let ui: TestForm
  hooks.beforeEach(function () {
    ui = new TestForm()
  })

  test('the components are exported as well as registered', function (assert) {
    for (const layout of [Horizontal, Compact, CheckboxAfter, Actions]) assert.ok(layout)
  })

  test('horizontal: the label in its own column, then control, hint and errors', async function (assert) {
    const model = { email: '' }

    await render(
      <template>
        <Form @model={{model}} @layout="horizontal" as |f|>
          <f.Field @for="email" @label="Email" @hint="We never share it" @required={{true}} />
        </Form>
      </template>,
    )

    const field = '[data-test-fw-field="email"]'
    assert.dom(`${field} > label.fw-label.fw-horizontal-label`).exists()
    assert.dom(`${field} > label + .fw-horizontal-body`).exists()
    assert.dom(`${field} .fw-horizontal-body > .fw-control-area + .fw-hint + .fw-errors`).exists()
    await ui.email.fillIn('ada@example.com')
    assert.strictEqual(model.email, 'ada@example.com')
    await a11yAudit()
  })

  test('compact: label and control on one line, in source order', async function (assert) {
    const model = { name: '' }

    await render(
      <template>
        <Form @model={{model}} @layout="compact" as |f|>
          <f.Field @for="name" @label="Name" @hint="Short" />
        </Form>
      </template>,
    )

    const field = '[data-test-fw-field="name"]'
    assert.dom(`${field} > label.fw-label + .fw-control-area + .fw-hint + .fw-errors`).exists()
    assert.dom(`${field} > .fw-errors`).hasClass('fw-compact-errors')
    await a11yAudit()
  })

  test('checkbox-after: the checkbox, then its label', async function (assert) {
    const model = { agree: false }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="agree" @control="checkbox" @label="I agree" @layout="checkbox-after" />
        </Form>
      </template>,
    )

    const field = '[data-test-fw-field="agree"]'
    assert.dom(`${field} > .fw-control-area + label.fw-label`).exists()
    await click(`${field} label`)
    assert.true(model.agree, 'the label still toggles the checkbox')
    await a11yAudit()
  })

  for (const layout of LAYOUTS) {
    for (const control of GROUPS) {
      test(`${layout} × ${control}: the legend is the fieldset’s first child, and axe passes`, async function (assert) {
        const model = { size: 's', sizes: ['m'] }
        const path = control === 'radio' ? 'size' : 'sizes'

        await render(
          <template>
            <Form @model={{model}} @layout={{layout}} as |f|>
              <f.Field
                @for={{path}}
                @control={{control}}
                @label="Size"
                @hint="Pick"
                @options={{SIZES}}
                @storeKey={{true}}
                @required={{true}}
              />
            </Form>
          </template>,
        )

        const fieldset = document.querySelector(`[data-test-fw-field="${path}"] fieldset.fw-group`)
        assert.ok(fieldset, 'renders a fieldset')
        assert.strictEqual(fieldset?.firstElementChild?.tagName, 'LEGEND')
        assert.dom(fieldset!.firstElementChild!).hasText('Size*')
        await a11yAudit()
      })
    }
  }

  test('Actions: left and right slots for the form’s buttons', async function (assert) {
    const model = { name: '' }
    let deleted = false
    const remove = () => (deleted = true)

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="name" @label="Name" />
          <Actions>
            <:left><f.Submit>Save</f.Submit><f.Reset>Cancel</f.Reset></:left>
            <:right><f.Button @onClick={{remove}}>Delete</f.Button></:right>
          </Actions>
        </Form>
      </template>,
    )

    assert.dom('.fw-actions > .fw-actions-left [data-test-fw-submit]').hasText('Save')
    assert.dom('.fw-actions > .fw-actions-left [data-test-fw-reset]').hasText('Cancel')
    assert.dom('.fw-actions > .fw-actions-right [data-test-fw-button]').hasText('Delete')
    await click('[data-test-fw-button]')
    assert.true(deleted)
    await a11yAudit()
  })
})
