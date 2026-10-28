# @ember-formwright/maskito

## 1.3.0

### Minor Changes

- 5db314e: A `phone` control, from the new `@ember-formwright/maskito/phone` entry point: a `type="tel"`
  input masked per country by `@maskito/phone` and libphonenumber-js. It stores E.164
  (`+12125550123`) or `null`, and shows the number formatted. `field.Control` takes `@country`,
  `@strict`, `@national` and `@metadata`. `isValidPhone` checks a number in a validator, and
  `formatPhone` shows one in inline forms. `PhoneHarness` drives it in tests, from
  `@ember-formwright/maskito/test-support`. `@maskito/kit`, `@maskito/phone` and
  `libphonenumber-js` are optional peers: only the phone entry point needs them.

### Patch Changes

- Updated dependencies [aad9026]
- Updated dependencies [abc6560]
  - @ember-formwright/ember@1.3.0
  - @ember-formwright/test-support@1.3.0

## 1.2.0

### Patch Changes

- Updated dependencies [795950d]
  - @ember-formwright/ember@1.2.0

## 1.1.0

### Patch Changes

- Updated dependencies [b1b17bc]
- Updated dependencies [7d49917]
  - @ember-formwright/ember@1.1.0

## 1.0.0

### Major Changes

- a2ca3a6: Formwright 1.0: the successor to ember-foxy-forms, rebuilt as a v2 TypeScript addon for Ember
  6.12 LTS and 7. See MIGRATION.md for moving from ember-foxy-forms.

### Patch Changes

- Updated dependencies [a2ca3a6]
  - @ember-formwright/ember@1.0.0
