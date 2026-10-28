# Date picker

`@ember-formwright/power-calendar` adds a date picker and a date-range picker, built on
[ember-power-calendar](https://ember-power-calendar.com) 2 and ember-basic-dropdown. Dates are
worked out with the browser's `Date` and `Intl`, so there is no date library to install.

```bash
npm install @ember-formwright/power-calendar ember-power-calendar ember-basic-dropdown ember-concurrency
```

```ts
// app/app.ts
import { registerPowerCalendarControls } from '@ember-formwright/power-calendar'
import 'ember-basic-dropdown/styles'
import '@ember-formwright/power-calendar/theme.css' // optional: follows the Formwright theme

registerPowerCalendarControls() // @control="date-picker" and @control="date-range"
```

The calendar opens in a dropdown, which renders into a wormhole. Put one in your application
template, as for [power select](./power-select.md):

```gts
import BasicDropdownWormhole from 'ember-basic-dropdown/components/basic-dropdown-wormhole'

<template>
  {{outlet}}
  <BasicDropdownWormhole />
</template>
```

## A day, and a range

The trigger is a button showing the value, formatted with `Intl.DateTimeFormat` in the field's
`@locale`. A date-picker stores an ISO `YYYY-MM-DD` string. A date-range stores
`{ start, end }` once both ends are chosen: the first click starts the range, the second ends
it (in either order), and closing the calendar in between keeps the old range.

<Example @name="controls-date-picker" @title="date-picker and date-range" />

Both read a `Date` or a string starting with `YYYY-MM-DD`. Give `field.Control` these to change
how they behave:

| Argument                 |                                                                                        |
| ------------------------ | -------------------------------------------------------------------------------------- |
| `@storeDate`             | Store `Date`s (at local midnight) instead of ISO strings, e.g. for `@attr('date')`     |
| `@dateFormat`            | `Intl.DateTimeFormat` options for the trigger. Default `{ dateStyle: 'medium' }`       |
| `@disabledDates`         | Days that can't be chosen: dates, or weekday names (`'Sat'`, `'Sun'`)                  |
| `@startOfWeek`           | 0 (Sunday) to 6. Default: the locale's                                                 |
| `@renderInPlace`         | Render the calendar inside the field instead of the wormhole                           |
| `@minRange`, `@maxRange` | date-range: the shortest and longest range, in days. Default: none; one day is a range |

The field's `@min` and `@max` (ISO strings or dates) disable the days outside them.

The field wires the control up for you:

| Field                             | date-picker                                                        |
| --------------------------------- | ------------------------------------------------------------------ |
| its id, so `<label for>` finds it | the trigger `<button>`                                             |
| `@label`                          | the trigger's `aria-label`: the label, then the value it shows     |
| hint and errors                   | `aria-describedby`                                                 |
| invalid                           | `aria-invalid`                                                     |
| `@disabled`, `@readonly`          | a disabled trigger (there is no read-only calendar, like `select`) |
| `@inline @callout`                | the calendar renders in place, inside the popover                  |

## Inline, in a callout

Inline mode shows the value as text: give the field a `@format`. `formatDate` and
`formatDateRange` read whatever the control stores, and take a locale and
`Intl.DateTimeFormat` options.

<Example @name="controls-date-picker-inline" @title="@storeDate, @min, @max and weekends off, in a callout" />

```ts
import { formatDate, formatDateRange } from '@ember-formwright/power-calendar'

const longDate = (value: Date | null) => formatDate(value, { format: { dateStyle: 'full' } })
const stay = (value: DateRangeValue | null) => formatDateRange(value) // "Mar 4 – 9, 2026"
```

## Keyboard

The trigger opens the calendar with Enter or Space, and focus moves to the selected day (or
today). Arrow keys move between days and across months, and Enter chooses one. Choosing a day
closes the calendar (for a range, choosing its end) and puts focus back on the trigger.

While the calendar is open, Enter and Escape belong to it and don't reach the field: with
`@requireConfirm` or `@inline`, choosing with Enter doesn't commit, and the first Escape closes
the calendar rather than cancelling the edit. Once it is closed, Enter commits and Escape
cancels, as in any field.

## Testing

`DatePickerHarness`, from `@ember-formwright/power-calendar/test-support`, drives both
controls: `select(isoDate)` opens the calendar, pages to the month and clicks the day;
`selectRange(start, end)` chooses both ends. It also has `text`, `isOpen`, `open()`, `close()`,
`month`, `nextMonth()`, `previousMonth()`, `day(isoDate)` and `isDayDisabled(isoDate)`, on top
of [`FieldHarness`](../going-further/testing.md#field-harnesses). Each example's **Test** tab
uses it.

<div class="callout">

**Known limits**

- The calendar works in local time. A stored `Date` is the local midnight of the day chosen;
  an ISO string has no time zone at all.
- The trigger is a `<button>`. It doesn't take part in a native form submit; the control sets
  `data-fw-name` with the field's path.
- An app that registers its own power-calendar date library (moment, luxon) keeps it; the
  controls then format the calendar with that library.

</div>
