# @ember-formwright/file-upload

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

- 5db314e: New package: `file` and `files` controls on ember-file-upload 10. A drop zone around a native
  file input, with the chosen files listed by name and size. Without `@upload` the field stores
  `File`s; with it, each file uploads as it is chosen, with progress, and the field stores what
  the upload resolves to. `@accept` filters the picker and drops. `FileUploadHarness` (from
  `@ember-formwright/file-upload/test-support`) selects, drops, removes and waits for uploads,
  and `theme.css` follows the Formwright theme.

### Patch Changes

- Updated dependencies [aad9026]
- Updated dependencies [abc6560]
  - @ember-formwright/ember@1.3.0
  - @ember-formwright/test-support@1.3.0
