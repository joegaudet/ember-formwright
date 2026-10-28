# @ember-formwright/power-calendar

Date and date-range pickers for Formwright, powered by
[ember-power-calendar](https://ember-power-calendar.com) 2 and ember-basic-dropdown. Dates are
handled with the browser's `Date` and `Intl`: no moment or luxon needed.

```bash
npm install @ember-formwright/ember @ember-formwright/power-calendar ember-power-calendar ember-basic-dropdown ember-concurrency
```

```ts
// app/app.ts
import { registerPowerCalendarControls } from '@ember-formwright/power-calendar'
import 'ember-basic-dropdown/styles'
import '@ember-formwright/power-calendar/theme.css' // optional; after the Formwright theme

registerPowerCalendarControls() // @control="date-picker" and @control="date-range"
```

Render `<BasicDropdownWormhole />` (from `ember-basic-dropdown/components/basic-dropdown-wormhole`)
once in your application template; calendars open into it. In tests, add
`<div id="ember-basic-dropdown-wormhole"></div>` next to `#ember-testing` in `tests/index.html`.

```gts
<f.Field @for="checkIn" @control="date-picker" @label="Check-in" @min={{this.today}} />

{{! stores { start, end } once both ends are chosen }}
<f.Field @for="stay" @control="date-range" @label="Stay" />

{{! a Date, for @attr('date'); weekends off }}
<f.Field @for="shipsOn" @control="date-picker" @label="Ships on" @format={{formatDate}} as |field|>
  <field.Control @storeDate={{true}} @disabledDates={{array "Sat" "Sun"}} />
</f.Field>
```

A date-picker stores an ISO `YYYY-MM-DD` string, a date-range `{ start, end }` of them; with
`@storeDate`, `Date`s at local midnight. Both read either. The field's `@min`, `@max` and
`@locale` apply. `field.Control` also takes `@dateFormat` (`Intl.DateTimeFormat` options for
the trigger), `@disabledDates`, `@startOfWeek`, `@renderInPlace`, and for a range `@minRange`
and `@maxRange` (in days).

`formatDate(value, { locale, format })` and `formatDateRange(value, { locale, format })` turn a
stored value into text, for a field's `@format` in inline mode.

## Testing

```ts
import { DatePickerHarness } from '@ember-formwright/power-calendar/test-support'

class BookingForm extends FormHarness {
  @field(DatePickerHarness) declare checkIn: DatePickerHarness
  @field(DatePickerHarness) declare stay: DatePickerHarness
}

await booking.checkIn.select('2026-03-04') // opens, pages to March 2026, clicks the 4th
await booking.stay.selectRange('2026-03-04', '2026-03-09')
assert.strictEqual(booking.checkIn.text, 'Mar 4, 2026')
```

It also has `open()`, `close()`, `isOpen`, `month`, `nextMonth()`, `previousMonth()`,
`day(isoDate)`, `isDayDisabled(isoDate)` and `trigger`.

## Behaviour and known limits

- **Date library.** ember-power-calendar needs a registered date library.
  `registerPowerCalendarControls()` registers one built on `Date` and `Intl`
  (`nativeDateLibrary`), unless the app registered its own (moment, luxon) first.
- **Labels.** The trigger is a `<button>`, so `<label for>` points at it and clicking the label
  focuses it. Its `aria-label` is the field's label followed by what it shows
  ("Check-in: Mar 4, 2026").
- **Focus.** Opening the calendar focuses the selected day, else today. Choosing a day closes
  it and focuses the trigger. Inline and confirm modes focus the trigger.
- **Callouts.** In `@inline @callout` forms the calendar renders in place, inside the popover,
  so a click on a day doesn't close the callout.
- **Keyboard.** While the calendar is open, Enter and Escape belong to it and don't reach the
  field: with `@requireConfirm` or `@inline`, Enter on a day doesn't commit, and the first
  Escape closes the calendar instead of cancelling the edit.
- **Ranges.** The first click starts a range, the second ends it; the ends are put in order.
  Nothing is stored until both are chosen, and closing the calendar in between keeps the old
  range.
- **Time zones.** Values are calendar days in local time. ISO strings carry no zone; a string
  with a time (`2026-03-04T10:00Z`) is read by its date part.
- **Readonly.** There is no read-only calendar; like `select`, readonly disables the trigger.
- **Native submit.** The trigger is a button with no value; the wrapper carries `data-fw-name`
  with the field's path.
- **Ember and power-calendar versions.** Ember 6.12+ and ember-power-calendar 2 only.
