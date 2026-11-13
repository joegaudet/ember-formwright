# @ember-formwright/test-support

## 2.0.0

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
