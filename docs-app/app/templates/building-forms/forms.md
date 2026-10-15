# Forms

Everything a `<Form>` can do, argument by argument.

## Disabled and readonly

`@disabled` and `@readonly` reach every field, including those in nested forms. Readonly inputs
stay focusable and copyable. A control that has no readonly state (select, radio, checkbox)
is disabled instead.

<Example @name="form-states" @title="Disabled and readonly" />

## Auto-submit

With `@autoSubmit`, every committed change submits the form: settings pages, toggles, anything
that should save as you go. Changes made while a save is in flight are saved again once it
finishes, so the last value always reaches the server.

<Example @name="auto-submit" @title="Saves as you go" />

## Inline editing

`@inline` shows each field's value as text. Clicking it opens the control, and ✔ (or Enter)
applies the change. Add `@callout` and the control opens in a native
[popover](https://developer.mozilla.org/docs/Web/API/Popover_API) anchored to the value with
CSS anchor positioning, so no positioning library is needed. Esc or a click outside cancels.

<Example @name="inline-editing" @title="Click a value to edit it" />

## Confirming changes

`@requireConfirm` holds each change until the user applies it with ✔ or Enter. ✘ or Esc
throws it away. It is useful when every write is expensive, or when a half-typed value must
never reach the model. A field can opt in or out with its own `@requireConfirm`.

<Example @name="require-confirm" @title="Apply or cancel each change" />

## Lifecycle hooks

Hooks let your app react to what the form does. Submit the example empty, then with an email,
and watch the order they run in.

<Example @name="lifecycle" @title="Hooks, in order" @noModel={{true}} />

| Hook                            | When                                                                                                       |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `@onChange(path, value, model)` | After each value is written to the model.                                                                  |
| `@didNotSubmit(errors)`         | Validation stopped a submit. Focus has moved to the first invalid field.                                   |
| `@willSubmit(model)`            | Validation passed. Return `false` (or a promise of `false`) to cancel, for example after a confirm dialog. |
| `@onSubmit(model)`              | Saves. Default: the adapter's save.                                                                        |
| `@didSubmit(model)`             | The save (and nested saves) succeeded.                                                                     |
| `@failedSubmit(error)`          | The save threw. Without this hook the error is rethrown.                                                   |
| `@willReset(model)`             | Return `false` to cancel a reset.                                                                          |
| `@didReset(model)`              | After a reset.                                                                                             |

## Everything else

| Argument          |                                                                                                            |
| ----------------- | ---------------------------------------------------------------------------------------------------------- |
| `@model`          | The object being edited.                                                                                   |
| `@name`           | Names the form for tests: `data-test-fw-form="<name>"`. Default `"form"`.                                  |
| `@adapter`        | How the model is read, written, saved and rolled back. See [Data layers](../going-further/data-layers.md). |
| `@validator`      | A Standard Schema or a function. See [Validation](validation.md).                                          |
| `@resetOnDestroy` | Roll back unsaved changes on teardown. Default `true`.                                                     |
| `@legend`         | Nested forms only: the fieldset's legend.                                                                  |

Any HTML attribute you add (`class`, `id`, `aria-*`) lands on the `<form>` element.

<div class="callout">

**What happened to …?**

ember-foxy-forms also had notifications (`@successfulSubmitMessage` and friends), a navigation
guard, a destroy button, BEM and CSS-grid class options, testing classes and global settings
in `config/environment.js`. Formwright leaves those to your app: notify from `@didSubmit` and
`@failedSubmit`, guard routes with `f.state.isDirty`, style with the stable `.fw-*` classes
and `data-*` states, and test with the `data-test-fw-*` selectors. The
[migration guide](https://github.com/joegaudet/ember-formwright/blob/main/MIGRATION.md) has a recipe
for each.

</div>
