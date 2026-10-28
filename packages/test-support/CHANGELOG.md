# @ember-formwright/test-support

## 1.3.0

No changes in this release.

## 1.2.0

### Minor Changes

- 795950d: `f.state.status` names the form's state: `clean`, `dirty`, `invalid` (a submit failed
  validation) or `submitting`. The `<form>` (and a nested form's `<fieldset>`) carries it as
  `data-status`, and `FormHarness` reads it as `status`. `FormStatus` is exported for typing it.

## 1.1.0

No changes in this release.

## 1.0.0

### Major Changes

- a2ca3a6: Formwright 1.0: the successor to ember-foxy-forms, rebuilt as a v2 TypeScript addon for Ember
  6.12 LTS and 7. See MIGRATION.md for moving from ember-foxy-forms.
