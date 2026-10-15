# Usage

A form owns a model, saves it on submit, and can reset it to the values it last saved.

<Example @name="submit-and-reset" @title="Save and discard" />

## The model

`@model` can be any object:

- **A class with `@tracked` fields**, as in these examples. Changes re-render everything that
  reads them.
- **A plain object.** Formwright reads and writes it through Ember's `get` and `set`, so plain
  objects stay reactive too.
- **A WarpDrive / ember-data record**, with `@ember-formwright/warp-drive`. Submit calls
  `record.save()`, and reset calls `rollbackAttributes()`. See [Data layers](../going-further/data-layers.md).

## Submitting

Submitting validates the form (see [Validation](../building-forms/validation.md)), then saves:

- With `@onSubmit`, Formwright calls it with the model and awaits what it returns.
- Without it, the adapter saves: `model.save()` if the model has one.

Pressing Enter in a text field submits (when the form has a `<f.Submit>`), and so does clicking `<f.Submit>`. While the save is pending,
`f.state.isSubmitting` is true, the submit button is `aria-busy`, and a second submit joins
the one in flight instead of saving twice.

## Resetting

`<f.Reset>` (or `f.state.reset()`) puts every field back to the value it had when the form
rendered or last saved. With an adapter that can roll back (WarpDrive), the adapter does it
instead.

A form also resets unsaved changes when it is torn down, so leaving a page never leaves a
half-edited model behind. Pass `@resetOnDestroy={{false}}` to keep them.

## What a form yields

| Yielded               |                                                                                               |
| --------------------- | --------------------------------------------------------------------------------------------- |
| `f.Field`             | A field bound to this form.                                                                   |
| `f.Form`              | A nested form. See [Nested forms](../building-forms/nested-forms.md).                         |
| `f.Submit`, `f.Reset` | Buttons. Pass your own text as the block.                                                     |
| `f.Button`            | A plain button that shows a busy state while the promise returned by `@onClick` is pending.   |
| `f.Errors`            | Form-level errors, plus any error no field shows.                                             |
| `f.state`             | `isDirty`, `isSubmitting`, `isValid`, `errors`, `model`, `submit()`, `reset()`, `validate()`. |
