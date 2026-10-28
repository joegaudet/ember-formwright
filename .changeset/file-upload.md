---
'@ember-formwright/file-upload': minor
---

New package: `file` and `files` controls on ember-file-upload 10. A drop zone around a native
file input, with the chosen files listed by name and size. Without `@upload` the field stores
`File`s; with it, each file uploads as it is chosen, with progress, and the field stores what
the upload resolves to. `@accept` filters the picker and drops. `FileUploadHarness` (from
`@ember-formwright/file-upload/test-support`) selects, drops, removes and waits for uploads,
and `theme.css` follows the Formwright theme.
