import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, triggerKeyEvent, waitUntil } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { FormHarness, field } from '@ember-formwright/test-support'
import {
  registerPowerCalendarControls,
  formatDate,
  formatDateRange,
  type DateRangeValue,
} from '@ember-formwright/power-calendar'
import { DatePickerHarness } from '@ember-formwright/power-calendar/test-support'

registerPowerCalendarControls()

class Trip {
  @tracked departure: string | Date | null = null
  @tracked stay: DateRangeValue | null = null
}

class TripForm extends FormHarness {
  @field(DatePickerHarness) declare departure: DatePickerHarness
  @field(DatePickerHarness) declare stay: DatePickerHarness
}

const EN = 'en-US'

module('Integration | power-calendar', function (hooks) {
  setupRenderingTest(hooks)

  let ui: TripForm
  hooks.beforeEach(function () {
    ui = new TripForm()
  })

  test('date-picker stores an ISO date, with the field wired to its trigger', async function (assert) {
    const trip = new Trip()

    await render(
      <template>
        <Form @model={{trip}} as |f|>
          <f.Field
            @for="departure"
            @control="date-picker"
            @label="Departure"
            @hint="When you leave"
            @placeholder="Pick a day"
            @required={{true}}
            @locale={{EN}}
          />
        </Form>
      </template>,
    )

    const trigger = ui.departure.trigger
    assert.dom('[data-test-fw-field="departure"] label').hasAttribute('for', trigger.id)
    assert.dom(trigger).hasTagName('button').hasAttribute('type', 'button')
    assert.dom(trigger).hasAttribute('aria-label', 'Departure: Pick a day')
    assert.dom(trigger).hasAttribute('aria-describedby', `${trigger.id}-hint`)
    assert.dom(trigger).hasAttribute('aria-expanded', 'false')
    assert.dom(trigger).hasText('Pick a day')
    assert
      .dom('[data-test-fw-field="departure"] [data-test-fw-control]')
      .hasAttribute('data-test-fw-control', 'date-picker')
      .hasAttribute('data-fw-name', 'form.departure')

    await ui.departure.select('2026-03-04')
    assert.strictEqual(trip.departure, '2026-03-04')
    assert.false(ui.departure.isOpen, 'choosing a day closes the calendar')
    assert.dom(trigger).isFocused('focus goes back to the trigger')
    assert.strictEqual(ui.departure.text, 'Mar 4, 2026')
    assert.dom(trigger).hasAttribute('aria-label', 'Departure: Mar 4, 2026')
    assert.true(ui.departure.isDirty)
  })

  test('it reads a Date or an ISO string, opens on its month, and @storeDate stores a Date', async function (assert) {
    const trip = new Trip()
    trip.departure = new Date(2026, 6, 14, 15, 30)
    trip.stay = { start: '2026-02-03T00:00:00Z', end: '2026-02-07' }

    await render(
      <template>
        <Form @model={{trip}} as |f|>
          <f.Field @for="departure" @control="date-picker" @label="Departure" as |field|>
            <field.Control @storeDate={{true}} @locale={{EN}} />
          </f.Field>
          <f.Field @for="stay" @control="date-range" @label="Stay" @locale={{EN}} />
        </Form>
      </template>,
    )

    assert.strictEqual(ui.departure.text, 'Jul 14, 2026')
    assert.strictEqual(ui.stay.text, 'Feb 3 – 7, 2026')

    await ui.departure.open()
    assert.strictEqual(ui.departure.month, 'July 2026', 'opens on the value’s month')
    assert
      .dom(ui.departure.day('2026-07-14'))
      .hasAttribute('aria-selected', 'true')
      .hasClass('ember-power-calendar-day--selected')

    await ui.departure.select('2026-08-01')
    assert.true(trip.departure instanceof Date, 'stores a Date')
    assert.deepEqual(trip.departure, new Date(2026, 7, 1), 'at local midnight')
  })

  test('date-range stores { start, end } once both ends are chosen', async function (assert) {
    const trip = new Trip()

    await render(
      <template>
        <Form @model={{trip}} as |f|>
          <f.Field
            @for="stay"
            @control="date-range"
            @label="Stay"
            @placeholder="Check-in – check-out"
            @locale={{EN}}
          />
        </Form>
      </template>,
    )

    await ui.stay.select('2026-05-20')
    assert.strictEqual(trip.stay, null, 'the first click only starts the range')
    assert.true(ui.stay.isOpen, 'and keeps the calendar open')
    assert.dom(ui.stay.day('2026-05-20')).hasClass('ember-power-calendar-day--range-start')

    await ui.stay.select('2026-05-17')
    assert.deepEqual(trip.stay, { start: '2026-05-17', end: '2026-05-20' }, 'ends are ordered')
    assert.false(ui.stay.isOpen)
    assert.strictEqual(ui.stay.text, 'May 17 – 20, 2026')

    await ui.stay.open()
    assert.dom(ui.stay.day('2026-05-18')).hasClass('ember-power-calendar-day--selected')
    await ui.stay.select('2026-06-02')
    await ui.stay.close()
    assert.deepEqual(
      trip.stay,
      { start: '2026-05-17', end: '2026-05-20' },
      'closing with only a start keeps the old range',
    )

    await ui.stay.selectRange('2026-06-02', '2026-06-02')
    assert.deepEqual(trip.stay, { start: '2026-06-02', end: '2026-06-02' }, 'one day is a range')
  })

  test('@min and @max disable the days outside them', async function (assert) {
    const trip = new Trip()

    await render(
      <template>
        <Form @model={{trip}} as |f|>
          <f.Field
            @for="departure"
            @control="date-picker"
            @label="Departure"
            @min="2026-03-10"
            @max="2026-04-05"
          />
        </Form>
      </template>,
    )

    assert.true(await ui.departure.isDayDisabled('2026-03-09'))
    assert.false(await ui.departure.isDayDisabled('2026-03-10'))
    assert.false(await ui.departure.isDayDisabled('2026-04-05'))
    assert.true(await ui.departure.isDayDisabled('2026-04-06'))

    await ui.departure.select('2026-03-12')
    assert.strictEqual(trip.departure, '2026-03-12')
  })

  test('disabled and readonly disable the trigger; reset restores the value', async function (assert) {
    const trip = new Trip()
    trip.departure = '2026-01-15'

    await render(
      <template>
        <Form @model={{trip}} as |f|>
          <f.Field @for="departure" @control="date-picker" @label="Departure" @locale={{EN}} />
          <f.Field
            @for="stay"
            @control="date-range"
            @label="Stay"
            @disabled={{true}}
            @locale={{EN}}
          />
          <f.Reset />
        </Form>
      </template>,
    )

    assert.dom(ui.stay.trigger).isDisabled()

    await ui.departure.select('2026-01-20')
    assert.strictEqual(trip.departure, '2026-01-20')
    await ui.reset()
    assert.strictEqual(trip.departure, '2026-01-15')
    assert.strictEqual(ui.departure.text, 'Jan 15, 2026')

    await render(
      <template>
        <Form @model={{trip}} @readonly={{true}} as |f|>
          <f.Field @for="departure" @control="date-picker" @label="Departure" />
        </Form>
      </template>,
    )
    assert.dom(ui.departure.trigger).isDisabled('readonly disables it, like select')
  })

  test('inline mode with @format shows the value, and the dropdown commits on confirm', async function (assert) {
    const trip = new Trip()
    trip.stay = { start: '2026-03-04', end: '2026-03-09' }
    const showDate = (value: unknown) => formatDate(value, { locale: EN })
    const showRange = (value: unknown) => formatDateRange(value, { locale: EN })

    await render(
      <template>
        <Form @model={{trip}} @inline={{true}} as |f|>
          <f.Field
            @for="departure"
            @control="date-picker"
            @label="Departure"
            @format={{showDate}}
          />
          <f.Field @for="stay" @control="date-range" @label="Stay" @format={{showRange}} />
        </Form>
      </template>,
    )

    assert.strictEqual(ui.stay.displayText, 'Mar 4 – 9, 2026')
    await ui.departure.edit()
    assert.dom(ui.departure.trigger).isFocused('editing focuses the trigger')
    await ui.departure.select('2026-03-01')
    assert.strictEqual(trip.departure, null, 'inline mode waits for the commit')
    await ui.departure.commit()
    assert.strictEqual(trip.departure, '2026-03-01')
    assert.strictEqual(ui.departure.displayText, 'Mar 1, 2026')
  })

  test('in a callout, the calendar renders inside the popover and choosing keeps it open', async function (assert) {
    const trip = new Trip()

    await render(
      <template>
        <Form @model={{trip}} @inline={{true}} @callout={{true}} as |f|>
          <f.Field @for="departure" @control="date-picker" @label="Departure" />
        </Form>
      </template>,
    )

    await ui.departure.edit()
    const popover = ui.departure.element.querySelector<HTMLElement>('[popover]')!
    assert.true(popover.matches(':popover-open'))
    assert.dom(ui.departure.trigger).isFocused()

    await ui.departure.open()
    assert.dom('.fw-calendar', popover).exists('the calendar is inside the popover')

    await ui.departure.select('2026-09-09')
    assert.true(popover.matches(':popover-open'), 'choosing a day does not close the callout')
    assert.strictEqual(trip.departure, null, 'not committed yet')
    await ui.departure.commit()
    assert.strictEqual(trip.departure, '2026-09-09')
  })

  test('keyboard with @requireConfirm: Enter chooses without committing, Escape closes the calendar first', async function (assert) {
    const trip = new Trip()
    trip.departure = '2026-03-04'

    await render(
      <template>
        <Form @model={{trip}} @requireConfirm={{true}} as |f|>
          <f.Field @for="departure" @control="date-picker" @label="Departure" as |field|>
            <field.Control @renderInPlace={{true}} />
          </f.Field>
        </Form>
      </template>,
    )

    const trigger = ui.departure.trigger
    await ui.departure.select('2026-03-05')
    assert.strictEqual(trip.departure, '2026-03-04', 'choosing does not commit the field')
    assert.dom('[data-test-fw-commit]').exists('the choice waits for confirm')

    await ui.departure.open()
    const day = ui.departure.day('2026-03-06')!
    day.focus()
    await triggerKeyEvent(day, 'keydown', 'Enter')
    assert.strictEqual(trip.departure, '2026-03-04', 'Enter in the calendar does not commit')
    // A browser clicks a focused button on Enter; the test helper only sends the key.
    await click(day)
    assert.false(ui.departure.isOpen)
    assert.strictEqual(trip.departure, '2026-03-04')

    await ui.departure.open()
    await triggerKeyEvent(ui.departure.day('2026-03-06')!, 'keydown', 'Escape')
    assert.false(ui.departure.isOpen, 'the first Escape closes the calendar')
    assert.dom(trigger).isFocused()
    assert.dom('[data-test-fw-commit]').exists('... and keeps the pending choice')

    await triggerKeyEvent(trigger, 'keydown', 'Escape')
    assert.dom('[data-test-fw-commit]').doesNotExist('the second Escape cancels the field')
    assert.strictEqual(ui.departure.text, 'Mar 4, 2026')

    await ui.departure.select('2026-03-07')
    await triggerKeyEvent(trigger, 'keydown', 'Enter')
    assert.strictEqual(trip.departure, '2026-03-07', 'Enter on the closed trigger commits')
  })

  test('both controls pass axe: closed, open, and invalid', async function (assert) {
    const trip = new Trip()
    trip.stay = { start: '2026-03-04', end: '2026-03-09' }
    const validator = (t: Trip): ErrorMap =>
      t.departure ? {} : { departure: ['Pick a departure'], stay: ['Check your dates'] }

    await render(
      <template>
        <Form @model={{trip}} @validator={{validator}} as |f|>
          <f.Field
            @for="departure"
            @control="date-picker"
            @label="Departure"
            @hint="When you leave"
            @placeholder="Pick a day"
          />
          <f.Field @for="stay" @control="date-range" @label="Stay" />
          <f.Submit />
        </Form>
      </template>,
    )

    await a11yAudit()
    await ui.stay.open()
    await a11yAudit()
    await ui.stay.close()

    await ui.submit()
    await waitUntil(() => ui.departure.isInvalid)
    assert.dom(ui.departure.trigger).hasAttribute('aria-invalid', 'true')
    assert.dom(ui.stay.trigger).hasAttribute('aria-invalid', 'true')
    assert.deepEqual(ui.departure.errors, ['Pick a departure'])
    await a11yAudit()
  })
})
