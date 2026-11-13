# @ember-formwright/power-calendar

## 2.0.0

### Major Changes

- 199233b: Fields type their control against their path. `@control` must be a control that stores what the
  path holds, and a field takes only its control's args, typed for that path. `ControlSignature`
  is split into the wiring every control gets and its own args, and registered names are declared
  in `FormwrightControls` (or `FormwrightChoiceControls<T>`, for controls whose value follows the
  path). The add-ons declare their default names. See MIGRATION.md.

### Minor Changes

- 332f045: Built-in strings are translatable. Register a translator as `translator:main` (an object with
  `locale` and `t(message, values)`) and Submit, Reset, the ✔ and ✘ buttons' names, the file
  upload's prompts, the rich-text toolbar and the date picker's trigger name all go through it;
  without one they stay English. Each package exports its messages at `./messages`, with ids
  `formwright.<component>.<name>`, and `@ember-formwright/ember` exports `translate`, `format` and
  the `Message` and `Translator` types.

  Strings that couldn't be changed before take arguments, which win over the translator:
  `@applyLabel` and `@cancelLabel` on fields; `@dropLabel`, `@dropHint`, `@retryLabel`,
  `@removeLabel`, `@uploadingLabel` and `@rejectedLabel` on the file upload control;
  `@toolbarLabel` and `@toolLabels` on the rich-text control.

  `@ember-formwright/test-support` adds `registerTranslator` and `pseudoTranslator`, to check in a
  test that every string goes through the translator.

### Patch Changes

- Updated dependencies [332f045]
- Updated dependencies [199233b]
  - @ember-formwright/ember@2.0.0
  - @ember-formwright/test-support@2.0.0

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
