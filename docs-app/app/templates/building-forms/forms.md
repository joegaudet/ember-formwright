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

`@inline` shows each field's value as text. Clicking it opens the control, and ✓ (or Enter)
applies the change. Add `@callout` and the control opens in a native
[popover](https://developer.mozilla.org/docs/Web/API/Popover_API) anchored to the value with
CSS anchor positioning, so no positioning library is needed. Esc or a click outside cancels.

<Example @name="inline-editing" @title="Click a value to edit it" />

## Confirming changes

`@requireConfirm` holds each change until the user applies it with ✓ or Enter. ✕ or Esc
throws it away. It is useful when every write is expensive, or when a half-typed value must
never reach the model. A field can opt in or out with its own `@requireConfirm`.

<Example @name="require-confirm" @title="Apply or cancel each change" />

## States

A form is always in one of four states. Read it as `f.state.status`, or as `data-status` on
the `<form>` for CSS and tests.

| Status       | When                                                                         | Leaves when                                   |
| ------------ | ---------------------------------------------------------------------------- | --------------------------------------------- |
| `clean`      | Every field matches its baseline: the value it rendered with, or last saved. | A value changes.                              |
| `dirty`      | A field differs from its baseline.                                           | You submit, reset, or put the value back.     |
| `invalid`    | A submit failed validation. The form re-validates on every change.           | The errors are fixed (`dirty`), or you reset. |
| `submitting` | The save is in flight, and `<f.Submit>` is busy.                             | It saves (`clean`), or it fails (`dirty`).    |

<Example @name="form-status" @title="Watch the status change" />

The same machine runs with every data layer; only where the pending changes live differs. The
[Changesets](../going-further/changesets.md#one-state-machine-three-data-layers) page animates it
with the default adapter, WarpDrive and ember-changeset. A nested form reports its own status
on its fieldset, and shares its root's `submitting` and `invalid`.

### Asking the status: `is` and `isNot`

`f.state.status` is a `FormStatus`, a [real-enums](https://joegaudet.com/real-enums/) enum, not
a string. Ask it a question instead of comparing strings:

```hbs
{{#if f.state.status.isSubmitting}}Saving…{{/if}}
{{#if f.state.status.isNotClean}}You have unsaved changes.{{/if}}
```

| Predicate                         | True when the status is…     |
| --------------------------------- | ---------------------------- |
| `isClean`, `isNotClean`           | `clean` / anything else      |
| `isDirty`, `isNotDirty`           | `dirty` / anything else      |
| `isInvalid`, `isNotInvalid`       | `invalid` / anything else    |
| `isSubmitting`, `isNotSubmitting` | `submitting` / anything else |

In code, compare it with a member: `state.status === FormStatus.Dirty`. To show it, render
`{{f.state.status.value}}` (the plain string, `dirty`); Glint won't take the enum itself as
text. `status.label` is `Dirty`, and `FormStatus.values` lists all four, in order.

### Events

The form runs a [Switchyard](https://joegaudet.com/switchyard/) state machine. Your app sends
it events through the form; the machine decides what each one does from the state it's in.

| Event    | Sent by                                 | What it does                                                      |
| -------- | --------------------------------------- | ----------------------------------------------------------------- |
| `submit` | `<f.Submit>`, Enter, `f.state.submit()` | Validates. Invalid: `invalid`. Valid: `@willSubmit`, then saves.  |
| `change` | a control, or ✓ under `@requireConfirm` | Writes the value. After a failed submit, re-validates.            |
| `reset`  | `<f.Reset>`, `f.state.reset()`          | `@willReset`, then rolls back, clears errors and a failed submit. |

A submit while one is saving joins it instead of saving twice; with `@autoSubmit` a change
during a save saves once more when it finishes. A failed validation is remembered until the
next save or reset, so the form keeps re-validating on change, even across a failed save.
Clean and dirty aren't events: the form works them out by comparing each value with its
baseline, so a change made outside the form still counts.

### Field status

Each field has a status too, for the moment between choosing a value and applying it. A
layout reads it as `@field.status`, a `FieldStatus`:

| Status    | When                                                                    |
| --------- | ----------------------------------------------------------------------- |
| `idle`    | Showing its value, or a live control that writes straight to the model. |
| `editing` | Its inline editor is open. It may hold a value awaiting ✓ or ✕.         |
| `pending` | It holds a value awaiting ✓ or ✕, outside an inline editor.             |

Its events are `edit` (open the inline editor), `change` (hold a value, when it needs a
confirm), `commit` (✓ or Enter: write the value) and `cancel` (✕ or Esc, or a reset). Ask it
`status.isPending`, `status.isNotIdle`, and so on, as with the form.

<Example @name="field-status" @title="A field holding a value" />

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
