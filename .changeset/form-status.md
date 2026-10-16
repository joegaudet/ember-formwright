---
'@ember-formwright/ember': minor
'@ember-formwright/test-support': minor
---

`f.state.status` names the form's state: `clean`, `dirty`, `invalid` (a submit failed
validation) or `submitting`. The `<form>` (and a nested form's `<fieldset>`) carries it as
`data-status`, and `FormHarness` reads it as `status`. `FormStatus` is exported for typing it.
