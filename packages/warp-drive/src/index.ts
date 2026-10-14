import { pojoAdapter, type ModelAdapter } from '@formwright/ember'

/** The parts of a WarpDrive / ember-data record this adapter uses. All optional. */
interface RecordLike {
  save?(): Promise<unknown>
  rollbackAttributes?(): void
  hasDirtyAttributes?: boolean
  isNew?: boolean
  isDeleted?: boolean
  errors?: { errorsFor?(attribute: string): ArrayLike<{ message: string }> }
}

/**
 * Lets Formwright forms edit WarpDrive / ember-data records:
 *
 * - submit calls `record.save()`
 * - reset calls `record.rollbackAttributes()`
 * - server errors on `record.errors` show on their fields; `base` errors show in `<f.Errors />`
 * - nested forms save their record when it is dirty, new or deleted
 *
 * Use it per form (`<Form @adapter={{warpDriveAdapter}}>`) or for every form:
 * `setDefaultAdapter(warpDriveAdapter)` in your app.ts.
 */
export const warpDriveAdapter: ModelAdapter<RecordLike> = {
  get: pojoAdapter.get,
  set: pojoAdapter.set,
  save: record => record.save?.(),
  rollback: record => record.rollbackAttributes?.(),
  errorsFor(record, path) {
    const errors = record.errors?.errorsFor?.(path === '' ? 'base' : path)
    return errors ? Array.from(errors, e => e.message) : []
  },
  needsSave: record => Boolean(record.hasDirtyAttributes || record.isNew || record.isDeleted),
}
