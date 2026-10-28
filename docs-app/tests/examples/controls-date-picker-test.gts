import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, field } from '@ember-formwright/test-support'
import { DatePickerHarness } from '@ember-formwright/power-calendar/test-support'
import BookingForm, { createModel } from 'docs-app/examples/controls-date-picker'

class BookingHarness extends FormHarness {
  static formName = 'booking'
  @field(DatePickerHarness) declare checkIn: DatePickerHarness
  @field(DatePickerHarness) declare stay: DatePickerHarness
}

module('Example | controls-date-picker', function (hooks) {
  setupRenderingTest(hooks)

  test('choose a day, then a range', async function (assert) {
    const model = createModel()
    await render(<template><BookingForm @model={{model}} /></template>)
    const booking = new BookingHarness()

    assert.strictEqual(booking.checkIn.text, 'Nov 12, 2026')
    await booking.checkIn.select('2026-12-03')
    assert.strictEqual(model.checkIn, '2026-12-03')

    await booking.stay.selectRange('2026-12-03', '2026-12-07')
    assert.deepEqual(model.stay, { start: '2026-12-03', end: '2026-12-07' })
    assert.strictEqual(booking.stay.text, 'Dec 3 – 7, 2026')

    await booking.stay.open()
    await a11yAudit()
  })
})
