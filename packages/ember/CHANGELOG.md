# @ember-formwright/ember

## 1.3.0

### Minor Changes

- aad9026: Pluggable field layouts. `@layout` on a `Form` (inherited by nested forms) or a `Field` takes
  a registered name or a component; `registerLayout` and `setDefaultLayout` work like
  `registerControl` and `setDefaultAdapter`. A layout receives pre-wired parts (`Label`, `Hint`,
  `Control`, `Errors`, `Group`) and read-only field state, and places them inside the field's
  `div.fw-field`. The default layout renders the same markup as before.

  New package, `@ember-formwright/layouts`: `horizontal`, `compact` and `checkbox-after` layouts
  with their CSS, and an `Actions` bar with `left` and `right` slots.

- abc6560: New package, `@ember-formwright/power-select`: `@control="power-select"` and
  `@control="power-select-multiple"` on ember-power-select 9, with search, async options, a
  `PowerSelectHarness` (`@ember-formwright/power-select/test-support`) and theme hooks.

  In the core, inline and confirm modes now focus the element carrying the field's id, so
  controls whose focusable element isn't an input (a power-select trigger) get focus. Controls
  receive `@callout` when they render inside a callout popover. An inline field whose object
  value isn't among its options shows the value's label instead of `[object Object]`.

## 1.2.0

### Minor Changes

- 795950d: `f.state.status` names the form's state: `clean`, `dirty`, `invalid` (a submit failed
  validation) or `submitting`. The `<form>` (and a nested form's `<fieldset>`) carries it as
  `data-status`, and `FormHarness` reads it as `status`. `FormStatus` is exported for typing it.

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
