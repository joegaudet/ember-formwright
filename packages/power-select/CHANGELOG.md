# @ember-formwright/power-select

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
