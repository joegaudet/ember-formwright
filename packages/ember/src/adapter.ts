import { get, set } from '@ember/object'

/**
 * How a form reads and writes its model. The core only needs `get` and `set`; everything
 * else is optional and lets a data layer (WarpDrive, a REST client, ...) plug in its own
 * persistence, rollback and server-side errors.
 */
export interface ModelAdapter<M extends object = object> {
  get(model: M, path: string): unknown
  set(model: M, path: string, value: unknown): void
  /** Persists the model. Default: `model.save()` if it exists. */
  save?(model: M): unknown
  /** Throws away unsaved changes. Default: the form restores the values it saw first. */
  rollback?(model: M): void
  /** Errors the data layer already knows about (e.g. returned by the server). */
  errorsFor?(model: M, path: string): string[]
  /** Whether a nested form's model needs saving when the root form submits. */
  needsSave?(model: M): boolean
}

/**
 * Works with any object: POJOs, classes with `@tracked` fields, and Ember objects.
 * Ember's `get`/`set` keep plain objects reactive.
 */
export const pojoAdapter: ModelAdapter = {
  get: (model, path) => get(model, path),
  set: (model, path, value) => {
    set(model, path, value)
  },
  save: model => {
    const save = (model as { save?: () => unknown }).save
    return typeof save === 'function' ? save.call(model) : undefined
  },
}

let defaultAdapter: ModelAdapter = pojoAdapter

/** Sets the adapter forms use when they aren't given `@adapter`. Call it once at boot. */
export function setDefaultAdapter(adapter: ModelAdapter<any>): void {
  defaultAdapter = adapter
}

export function getDefaultAdapter(): ModelAdapter {
  return defaultAdapter
}
