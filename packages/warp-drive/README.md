# @formwright/warp-drive

Lets Formwright forms edit WarpDrive and ember-data records.

```bash
npm install @formwright/ember @formwright/warp-drive
```

```ts
// app/app.ts: every form
import { setDefaultAdapter } from '@formwright/ember'
import { warpDriveAdapter } from '@formwright/warp-drive'

setDefaultAdapter(warpDriveAdapter)
```

or one form: `<Form @model={{@post}} @adapter={{warpDriveAdapter}}>`.

| Form action       | Record                                                                |
| ----------------- | --------------------------------------------------------------------- |
| Submit            | `record.save()`                                                       |
| Reset             | `record.rollbackAttributes()`                                         |
| Field errors      | `record.errors.errorsFor(path)`; `base` errors show in `<f.Errors />` |
| Nested `<f.Form>` | Saved with the root when `hasDirtyAttributes`, `isNew` or `isDeleted` |

The adapter only reads those members, so any record-like object that has them works.
