# Data layers

The core edits any object through a `ModelAdapter`. The default adapter reads and writes with
Ember's `get`/`set` and saves with `model.save()` if there is one. That covers plain objects,
`@tracked` classes and most records. Adapters teach it more.

```ts
interface ModelAdapter<M> {
  get(model: M, path: string): unknown
  set(model: M, path: string, value: unknown): void
  save?(model: M): unknown // submit
  rollback?(model: M): void // reset
  errorsFor?(model: M, path: string): string[] // server errors; '' is form-level
  needsSave?(model: M): boolean // should a nested form save this model?
}
```

Without `rollback`, a reset uses Formwright's own baseline. See [Rolling back](#rolling-back).

Use one per form with `@adapter`, or for every form with `setDefaultAdapter()` at boot.

## WarpDrive and ember-data

```bash
npm install @ember-formwright/warp-drive
```

```ts
// app/app.ts
import { setDefaultAdapter } from '@ember-formwright/ember'
import { warpDriveAdapter } from '@ember-formwright/warp-drive'

setDefaultAdapter(warpDriveAdapter)
```

| The form does      | The record gets                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------- |
| submit             | `record.save()`                                                                          |
| reset              | `record.rollbackAttributes()`                                                            |
| show field errors  | `record.errors.errorsFor(path)`, so server-side validation errors appear on their fields |
| show form errors   | `record.errors.errorsFor('base')` in `<f.Errors />`                                      |
| save a nested form | when `hasDirtyAttributes`, `isNew` or `isDeleted`                                        |

## Changesets (ember-changeset)

```bash
npm install @ember-formwright/changeset ember-changeset
```

Pass a changeset as the model. Edits stay in the changeset, and the object underneath
changes only when a valid submit applies them.

<Example @name="data-changeset" @title="Editing through a changeset" />

| The form does      | The changeset gets                                                       |
| ------------------ | ------------------------------------------------------------------------ |
| read / write       | through the changeset, never the model                                   |
| validate           | `changeset.validate()`, with `@validator={{changesetValidator}}`         |
| submit             | `changeset.save()`: applies the changes, then calls the model's `save()` |
| reset              | `changeset.rollback()`                                                   |
| save a nested form | when its own changeset `isDirty`                                         |

Use `changesetValidator` whenever the changeset has validations. An invalid changeset's own
`save()` skips the changes but still saves the model, so `changesetAdapter` refuses to save
one. The validator stops the submit first and shows each message on its field.

Build the changeset with a validation map: `{{changeset @user UserValidations}}` with
`ember-changeset-validations`, or `Changeset(model, lookupValidator(map), map)`. A changeset
built from a single validator function only checks the fields that changed, so an empty
field nobody touched passes.

If the model's `save()` fails (a WarpDrive record and a 422, say), the adapter puts the
model's values back and the edits stay in the changeset, ready to retry or reset.

A nested form's `@model` is either its own changeset, saved with the root when dirty, or part
of the parent's (`@model={{@model.address}}`). Edits to a part land in the parent changeset,
which saves and rolls them back with everything else. For a nested object outside the
changeset, give that form its own `@adapter`.

## Rolling back

A reset (`<f.Reset>`, `f.state.reset()`, or a form torn down with unsaved changes) undoes
edits in one of three ways, depending on the adapter.

| Rollback                 | Who undoes it                 | While editing, the model | Reset puts back                                     |
| ------------------------ | ----------------------------- | ------------------------ | --------------------------------------------------- |
| Native (default adapter) | Formwright                    | changes as you type      | the fields' values from first render or last save   |
| WarpDrive                | `record.rollbackAttributes()` | changes as you type      | every attribute's last saved value                  |
| Changeset                | `changeset.rollback()`        | stays as it was          | nothing to put back: the buffered edits are dropped |

### Native rollback

With no rollback in the adapter, Formwright keeps its own baseline. Each field records its
value when it first renders, and every successful submit records the saved values again.
Reset writes each changed value back through the adapter.

- It only covers paths a field of the form has bound. Something else changing the model
  directly is not undone.
- The baseline is shallow: arrays are copied, objects are kept by reference. A field bound to
  `address.city` restores the city. A custom control that mutates an object in place cannot
  be undone. Bind the nested paths, or use a nested form.
- Anything else reading the model sees edits as they are typed. If it shouldn't, edit
  through a changeset.

### Changeset rollback

A changeset holds the edits and the model never sees them. Reset is `changeset.rollback()`,
which drops the pending changes and their validation errors at once. Nothing else reading
the model ever sees a half-edited value. Use a changeset when an edit should stay
private until it is saved, such as a modal over a list that shows the same record.

Either way, `<f.Reset>` and `f.state.reset()` run `@willReset` and `@didReset` on the form
that was reset, and nested forms reset with their parent. A torn-down form rolls back
without running the hooks.

## real-enums

[real-enums](https://joegaudet.com/real-enums/) classes work as options as they are: each
member has a `value` (the key) and a `label`. `@ember-formwright/real-enums` adds filtering, storing
the raw string, and labels for inline display.

<Example @name="data-real-enums" @title="Options from an enum class" />

| Helper                                  |                                                                    |
| --------------------------------------- | ------------------------------------------------------------------ |
| `enumOptions(Enum, { only?, except? })` | The members, in declaration order, optionally filtered.            |
| `enumValue`                             | `@optionKey` that stores the raw string; pair it with `@storeKey`. |
| `enumLabel(Enum)`                       | `@format` that shows a member's label for a raw value.             |

## Masked input (Maskito)

```bash
npm install @ember-formwright/maskito @maskito/core
```

<Example @name="data-maskito" @title="Phone and postal code masks" />

Any Maskito options work as `@mask`, including the generators in `@maskito/kit` for numbers,
dates and times. The model receives the masked text.
