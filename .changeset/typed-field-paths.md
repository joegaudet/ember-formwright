---
'@ember-formwright/ember': minor
---

The form's interface is now typed by its `@model`:

- `@for` on `f.Field` must be one of the model's paths, including nested (`address.city`) and
  array (`items.0.name`, `items[0].name`) paths.
- A field's block `value` and its `@format` argument take the type at that path.
- `f.Form` keeps its own model's type, so a nested form's fields are checked against it.
- `ErrorMap<Model>` is keyed by the model's paths (plus `''`). `f.state.errors`,
  `@didNotSubmit` and function validators use it. A bare `ErrorMap` is still
  `Record<string, string[]>`.
- `@onChange(path, value, model)` types `value` by `path`.
- `form.read`, `form.commit` and `form.errorsFor` are typed by path.
- New exported types: `Path<Model>` and `PathValue<Model, Path>`.

Loosely typed models (`any`, `object`, index signatures) still accept any string path and
give `unknown` values. `@adapter` no longer takes part in inferring the model type.
