# Validation

Give a form a `@validator`. Formwright runs it on submit, puts each message on its field,
moves focus to the first invalid one, and announces the errors. After a failed submit it
validates again on every change, so errors disappear as soon as they are fixed.

## Any Standard Schema

zod, valibot, ArkType: anything that implements [Standard Schema](https://standardschema.dev)
works as is. Each issue's path picks the field that shows it.

<Example @name="validation-zod" @title="A zod schema" />

valibot looks the same:

```ts
import * as v from 'valibot'

const schema = v.object({
  email: v.pipe(v.string(), v.email('That email looks off')),
})
```

## A function

A validator can also be a function, sync or async, that returns messages by path. Use the
empty path `''` for errors that belong to the whole form; `<f.Errors />` shows them.

<Example @name="validation-function" @title="Async checks and form-level errors" />

## Errors from elsewhere

An adapter can report errors too, such as the ones a server returned with a failed save. They
show on their fields next to the validator's. Any error whose path matches no field shows in
`<f.Errors />`, so a blocked submit is never silent.

| Error path        | Shows on                                          |
| ----------------- | ------------------------------------------------- |
| `"email"`         | `<f.Field @for="email">`                          |
| `"address.city"`  | `<f.Field @for="address.city">`, in the same form |
| `""`              | `<f.Errors />`                                    |
| no matching field | `<f.Errors />`                                    |

Nested forms validate their own model with their own `@validator`. See
[Nested forms](nested-forms.md).
