---
'@ember-formwright/changeset': minor
---

New package: `@ember-formwright/changeset`. `changesetAdapter` lets a form edit through an
ember-changeset changeset (edits stay buffered until a valid submit, reset calls
`changeset.rollback()`, nested forms save when dirty), and `changesetValidator` runs the
changeset's validations as the form's `@validator`.
