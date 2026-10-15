---
'@ember-formwright/ember': minor
---

`@for` on `f.Field` is now type-checked against the form's `@model`, including nested
(`address.city`) and array (`items.0.name`, `items[0].name`) paths. `f.Form` keeps its own
model's type, so a nested form's fields are checked against it. Loosely typed models (`any`,
`object`, index signatures) still accept any string. The new `Path<Model>` type is exported.
`@adapter` no longer takes part in inferring the model type.
