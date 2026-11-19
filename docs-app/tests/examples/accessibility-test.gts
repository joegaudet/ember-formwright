import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, RadioHarness, field } from '@ember-formwright/test-support'
import RsvpForm, { createModel } from 'docs-app/examples/accessibility'

class RsvpHarness extends FormHarness {
  static formName = 'rsvp'
  @field(InputHarness) declare name: InputHarness
  @field(RadioHarness) declare meal: RadioHarness
}

module('Example | accessibility', function (hooks) {
  setupRenderingTest(hooks)

  test('a failed submit focuses the first invalid control and announces its error', async function (assert) {
    const model = createModel()
    await render(<template><RsvpForm @model={{model}} /></template>)
    const rsvp = new RsvpHarness()

    await rsvp.submit()

    // Focus lands on the first invalid control.
    assert.dom(rsvp.name.control).isFocused()
    assert.dom(rsvp.name.control).hasAttribute('aria-invalid', 'true')

    // The control is described by its hint and its errors, and the errors are a live region.
    const ids = rsvp.name.control.getAttribute('aria-describedby')!.split(' ')
    const errors = rsvp.name.element.querySelector('[data-test-fw-errors]')!
    assert.true(ids.includes(errors.id), 'the errors describe the control')
    assert.dom(`#${ids[0]}`).hasText('As it appears on your ticket.')
    assert.dom(errors).hasAttribute('aria-live', 'polite')
    assert.dom(errors).hasText('Please enter your name')

    // A radio group is a fieldset named by its legend; the fieldset carries the description.
    const group = rsvp.meal.element.querySelector('fieldset')!
    assert.dom(group.querySelector('legend')).exists()
    assert.strictEqual(rsvp.meal.label, 'Meal')
    assert
      .dom(group)
      .hasAttribute(
        'aria-describedby',
        rsvp.meal.element.querySelector('[data-test-fw-errors]')!.id,
      )
    assert.deepEqual(rsvp.meal.errors, ['Please pick a meal'])
    for (const radio of group.querySelectorAll('input[type="radio"]')) {
      assert.dom(radio).hasAttribute('aria-invalid', 'true')
    }

    await a11yAudit()
  })
})
