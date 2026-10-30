# @ember-formwright/power-calendar

## 1.3.0

### Minor Changes

- 5db314e: New package: `date-picker` and `date-range` controls on ember-power-calendar 2. A button
  trigger, named by the field's label, opens the calendar in an ember-basic-dropdown; values are
  ISO `YYYY-MM-DD` strings (or `Date`s with `@storeDate`), and a range is `{ start, end }`. `@min`,
  `@max`, `@locale`, `@disabledDates`, callouts and confirm-mode keyboard handling are supported.
  Includes a `Date`/`Intl` date library for power-calendar (no moment or luxon), `formatDate` and
  `formatDateRange` for inline display, a theme following the Formwright custom properties, and
  `DatePickerHarness` at `@ember-formwright/power-calendar/test-support`.

### Patch Changes

- Updated dependencies [aad9026]
- Updated dependencies [abc6560]
  - @ember-formwright/ember@1.3.0
  - @ember-formwright/test-support@1.3.0
