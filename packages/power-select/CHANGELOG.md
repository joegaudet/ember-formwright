# @ember-formwright/power-select

## 2.0.0

### Major Changes

- 199233b: Fields type their control against their path. `@control` must be a control that stores what the
  path holds, and a field takes only its control's args, typed for that path. `ControlSignature`
  is split into the wiring every control gets and its own args, and registered names are declared
  in `FormwrightControls` (or `FormwrightChoiceControls<T>`, for controls whose value follows the
  path). The add-ons declare their default names. See MIGRATION.md.

### Patch Changes

- Updated dependencies [332f045]
- Updated dependencies [199233b]
  - @ember-formwright/ember@2.0.0
  - @ember-formwright/test-support@2.0.0

## 1.3.0

### Minor Changes

- abc6560: New package, `@ember-formwright/power-select`: `@control="power-select"` and
  `@control="power-select-multiple"` on ember-power-select 9, with search, async options, a
  `PowerSelectHarness` (`@ember-formwright/power-select/test-support`) and theme hooks.

  In the core, inline and confirm modes now focus the element carrying the field's id, so
  controls whose focusable element isn't an input (a power-select trigger) get focus. Controls
  receive `@callout` when they render inside a callout popover. An inline field whose object
  value isn't among its options shows the value's label instead of `[object Object]`.

### Patch Changes

- Updated dependencies [aad9026]
- Updated dependencies [abc6560]
  - @ember-formwright/ember@1.3.0
  - @ember-formwright/test-support@1.3.0
