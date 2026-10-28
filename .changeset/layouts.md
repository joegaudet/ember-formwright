---
'@ember-formwright/ember': minor
'@ember-formwright/layouts': minor
---

Pluggable field layouts. `@layout` on a `Form` (inherited by nested forms) or a `Field` takes
a registered name or a component; `registerLayout` and `setDefaultLayout` work like
`registerControl` and `setDefaultAdapter`. A layout receives pre-wired parts (`Label`, `Hint`,
`Control`, `Errors`, `Group`) and read-only field state, and places them inside the field's
`div.fw-field`. The default layout renders the same markup as before.

New package, `@ember-formwright/layouts`: `horizontal`, `compact` and `checkbox-after` layouts
with their CSS, and an `Actions` bar with `left` and `right` slots.
