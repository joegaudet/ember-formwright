# @ember-formwright/file-upload

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
