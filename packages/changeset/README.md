# @ember-formwright/changeset

Lets Formwright forms edit through an [ember-changeset](https://github.com/adopted-ember-addons/ember-changeset)
changeset. Edits stay in the changeset; the model underneath changes only when a valid submit
applies them.

```bash
npm install @ember-formwright/ember @ember-formwright/changeset ember-changeset
```

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

| Form action       | Changeset                                                                 |
| ----------------- | ------------------------------------------------------------------------- |
| Read / write      | Through the changeset, never the model                                    |
| Validate          | `changeset.validate()`, via `@validator={{changesetValidator}}`           |
| Submit            | `changeset.save()`: applies the changes, then saves the model             |
| Reset             | `changeset.rollback()`: drops the pending changes; the model is untouched |
| Nested `<f.Form>` | Its own changeset (saved when dirty) or part of the parent's              |

`changesetAdapter` refuses to save an invalid changeset, because `changeset.save()` would skip
the changes and still save the model. Use `changesetValidator` so an invalid submit stops
first and shows each message on its field.

Build the changeset with a validation map (`{{changeset @user Validations}}`): one built from a
single validator function only checks the fields that changed. If the model's `save()` fails,
the adapter puts the model's values back and the edits stay in the changeset.

The adapter only reads those members, so any changeset with them (validated-changeset
included) works.
