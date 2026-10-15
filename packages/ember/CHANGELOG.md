# @ember-formwright/ember

## 1.1.0

### Minor Changes

- 7d49917: The form's interface is now typed by its `@model`:

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

### Patch Changes

- b1b17bc: A nested form accepts a part of a loosely typed model as its `@model`, such as a changeset's
  `cs.address` (typed `unknown`). Its fields are typed loosely, like a loose top-level model.

## 1.0.0

### Major Changes

- a2ca3a6: Formwright 1.0: the successor to ember-foxy-forms, rebuilt as a v2 TypeScript addon for Ember
  6.12 LTS and 7. See MIGRATION.md for moving from ember-foxy-forms.
