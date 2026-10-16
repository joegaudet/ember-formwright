# Changesets

With [ember-changeset](https://github.com/adopted-ember-addons/ember-changeset), a form edits a
changeset instead of the model. Edits stay in the changeset until a valid submit applies
and saves them. Reset drops them, and the model never sees a half-made edit.

<Example @name="data-changeset" @title="Editing through a changeset" @noModel={{true}} />

## What forms already do, without a changeset

You may not need one. With a plain object or a `@tracked` class, a `<Form>` and its fields
already keep track of changes and undo them:

- **A baseline per field.** When a field first renders, its form records the value it shows.
  After a successful submit, the saved values become the new baseline.
- **One status.** `f.state.status` is `clean`, `dirty`, `invalid` or `submitting`, and
  `data-status` on the `<form>` mirrors it. See [States](../building-forms/forms.md#states).
- **Dirty state.** `f.state.isDirty` (and `data-dirty` on the form) is true while any field
  differs from its baseline. Type the old value back and the field is clean again. Nested forms
  count toward their parent.
- **Reset.** `<f.Reset>` writes each changed value back to the model with Ember's `set`, clears
  the errors, drops any unconfirmed drafts, and resets nested forms too.
- **Rollback on teardown.** Leaving a page with unsaved changes rolls them back, so a
  half-edited model never lingers. `@resetOnDestroy={{false}}` keeps them.
- **Drafts before the model.** With [`@requireConfirm`](../building-forms/forms.md) or
  `@inline`, a field holds a change as a draft until ✓ or Enter. ✕ or Esc drops it, and the
  model never sees it.
- **Nested saves.** Submit saves the root model, then each nested form that has changes,
  parents before children.

### When a changeset earns its place

- **Other UI must not see unsaved edits.** Without one, a field writes to the model as you type
  (or as you commit a draft), so anything else showing that model updates too. A changeset
  keeps every edit to itself until it saves.
- **Rollback beyond the fields.** Native rollback restores only the paths the form's fields
  bound, and keeps objects by reference. `changeset.rollback()` drops every pending change.
- **A failed save.** With a changeset the model goes back to how it was and the edits stay
  buffered to retry. Natively, the model already holds the edits.
- **Validations you already have**, written for `ember-changeset-validations`.

[Rolling back](../going-further/data-layers.md#rolling-back) compares the two in detail, and
the animation below shows both.

## Setup

1. **Install** the adapter next to ember-changeset:

   ```bash
   npm install @ember-formwright/changeset ember-changeset
   ```

2. **Describe the validations as a map**, one validator per field. Each returns `true`, or
   the message. `ember-changeset-validations` validators work here too.

   ```ts
   export const UserValidations = {
     email: (_key: string, value: unknown) => String(value).includes('@') || 'Enter an email',
   }
   ```

3. **Pass the changeset as the model**, with the adapter and the validator:

   ```hbs
   <Form
     @model={{changeset @user UserValidations}}
     @adapter={{changesetAdapter}}
     @validator={{changesetValidator}}
     as |f|
   >
     <f.Field @for='email' @label='Email' />
     <f.Submit />
     <f.Reset />
   </Form>
   ```

   In TypeScript, `Changeset(user, lookupValidator(UserValidations), UserValidations)` builds
   the same changeset.

## What the form does

| The form does      | The changeset gets                                                       |
| ------------------ | ------------------------------------------------------------------------ |
| read / write       | through the changeset, never the model                                   |
| validate           | `changeset.validate()`, with `@validator={{changesetValidator}}`         |
| submit             | `changeset.save()`: applies the changes, then calls the model's `save()` |
| reset              | `changeset.rollback()`                                                   |
| save a nested form | when its own changeset `isDirty`                                         |

## One state machine, three data layers

Every form runs the same [state machine](../building-forms/forms.md#states): `clean`, `dirty`,
`invalid` and `submitting`, read as `f.state.status`. The data layer never changes the states,
only where pending changes live and who rolls them back. In a form, every change writes
through the adapter at once. Inline, the field keeps a draft until you commit it
with ✓ or Enter, and ✕ or Esc drops it. Submit saves the pending changes, and Reset rolls them
back.

Here is where each one keeps them:

- **WarpDrive:** the record tracks its own dirty attributes, so anything else showing the
  record sees an edit straight away. Reset calls `rollbackAttributes()`.
- **ember-changeset:** the changeset holds the edits, and the model sees nothing until it
  saves. Reset calls `changeset.rollback()`.
- **Default:** with a plain object or `@tracked` class, edits go straight to the model and
  Formwright keeps a baseline: the values the fields had when they rendered or last saved.
  Reset writes the baseline back, and a successful submit records a new one.

Pick a mode and a data layer, then press **Play** or step through.

<CommitFlow />

| What you do         | Form                           | Inline                                       |
| ------------------- | ------------------------------ | -------------------------------------------- |
| Change a value      | written through the adapter    | kept as the field's draft                    |
| Commit (✓ or Enter) | (no draft)                     | the draft is written through the adapter     |
| Cancel (✕ or Esc)   | (no draft)                     | the draft is dropped; nothing was written    |
| Submit              | saves the pending changes      | saves the pending changes (or `@autoSubmit`) |
| Reset               | rolls the pending changes back | rolls committed changes back                 |

## Validation

Use `changesetValidator` whenever the changeset has validations. It stops an invalid submit
and shows each message on its field. Without it, an invalid changeset's own `save()` would skip
the changes but still save the model, so `changesetAdapter` refuses to save one.

Build the changeset with a validation map, as in step 2. A changeset built from a single
validator function only checks the fields that changed, so an empty field nobody touched
passes.

## Saving

`changeset.save()` applies the changes, then calls the model's `save()`. The model can be a
WarpDrive record. If its `save()` fails (a 422, say), the adapter puts the model's values back
and the edits stay in the changeset, ready to retry or reset.

## Rolling back

Reset calls `changeset.rollback()`, which drops the pending changes and their validation errors.
Nothing reading the model sees the edit, before or after. That makes a changeset the right
choice when an edit should stay private until it is saved, such as a modal over a list that
shows the same record.

Without a changeset, Formwright rolls back natively: it writes back the values the form's
fields had when they rendered or last saved. [Rolling back](../going-further/data-layers.md#rolling-back)
compares the two in full.

## Nested forms

A nested form's `@model` is either its own changeset, saved with the root when dirty, or part
of the parent's (`@model={{@model.address}}`). Edits to a part land in the parent changeset,
which saves and rolls them back with everything else. For a nested object outside the
changeset, give that form its own `@adapter`.
