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

Use one per form with `@adapter`, or for every form with `setDefaultAdapter()` at boot.

## WarpDrive and ember-data

```bash
npm install @formwright/warp-drive
```

```ts
// app/app.ts
import { setDefaultAdapter } from '@formwright/ember'
import { warpDriveAdapter } from '@formwright/warp-drive'

setDefaultAdapter(warpDriveAdapter)
```

| The form does      | The record gets                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------- |
| submit             | `record.save()`                                                                          |
| reset              | `record.rollbackAttributes()`                                                            |
| show field errors  | `record.errors.errorsFor(path)`, so server-side validation errors appear on their fields |
| show form errors   | `record.errors.errorsFor('base')` in `<f.Errors />`                                      |
| save a nested form | when `hasDirtyAttributes`, `isNew` or `isDeleted`                                        |

## real-enums

[real-enums](https://joegaudet.com/real-enums/) classes work as options as they are: each
member has a `value` (the key) and a `label`. `@formwright/real-enums` adds filtering, storing
the raw string, and labels for inline display.

<Example @name="data-real-enums" @title="Options from an enum class" />

| Helper                                  |                                                                    |
| --------------------------------------- | ------------------------------------------------------------------ |
| `enumOptions(Enum, { only?, except? })` | The members, in declaration order, optionally filtered.            |
| `enumValue`                             | `@optionKey` that stores the raw string; pair it with `@storeKey`. |
| `enumLabel(Enum)`                       | `@format` that shows a member's label for a raw value.             |

## Masked input (Maskito)

```bash
npm install @formwright/maskito @maskito/core
```

<Example @name="data-maskito" @title="Phone and postal code masks" />

Any Maskito options work as `@mask`, including the generators in `@maskito/kit` for numbers,
dates and times. The model receives the masked text.
