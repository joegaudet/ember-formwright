# Changesets

With [ember-changeset](https://github.com/adopted-ember-addons/ember-changeset), a form edits a
changeset instead of the model. Edits stay in the changeset until a valid submit applies
and saves them. Reset drops them, and the model never sees a half-made edit.

<Example @name="data-changeset" @title="Editing through a changeset" />

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
