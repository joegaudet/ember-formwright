---
'@ember-formwright/ember': major
---

Forms and fields run on [Switchyard](https://joegaudet.com/switchyard/) state machines, and
their status is a [real-enums](https://joegaudet.com/real-enums/) enum you can ask questions.

- `f.state.status` is a `FormStatus` member, not a string: `{{#if f.state.status.isSubmitting}}`,
  `{{#if f.state.status.isNotClean}}`, `state.status === FormStatus.Dirty`. Render
  `{{f.state.status.value}}` for the string; `data-status` on the form is unchanged.
- A layout's `@field.status` is a `FieldStatus`: `idle`, `editing` or `pending` (holding a
  value awaiting ✓ or ✕). Ask it `@field.status.isPending`.
- `FormStatus` and `FieldStatus` are exported. `FormStatus` was a type; it is now a class.
- A nested form's `f.state.isSubmitting` reports its root's submit, as its status already did.

See MIGRATION.md.
