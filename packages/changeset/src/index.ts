import { pojoAdapter, type ErrorMap, type ModelAdapter } from '@ember-formwright/ember'

/** The parts of an ember-changeset / validated-changeset changeset this package uses. */
interface ChangesetLike {
  get(path: string): unknown
  set(path: string, value: unknown): unknown
  save(): Promise<unknown>
  rollback(): unknown
  validate(): Promise<unknown>
  isDirty: boolean
  isInvalid: boolean
  errors: { key: string; validation: unknown }[]
  changes: Record<string, any>[] // each one { key, value }
  data: object
}

/**
 * Lets Formwright forms edit an ember-changeset changeset:
 *
 * - edits stay in the changeset; the model underneath changes only on submit
 * - submit calls `changeset.save()`, which applies the changes and saves the model
 * - reset calls `changeset.rollback()`
 * - a nested form's model is its own changeset (saved when dirty) or part of the parent's
 *
 * Pair it with `changesetValidator` to run the changeset's validations when the form validates.
 */
export const changesetAdapter: ModelAdapter<ChangesetLike> = {
  // Ember's get/set go through the changeset's proxy, which also covers a nested form over
  // part of it (`@model={{cs.address}}`): its edits land in the parent changeset.
  get: pojoAdapter.get,
  set: pojoAdapter.set,
  async save(changeset) {
    if (!isChangeset(changeset)) return // part of a changeset: its root saves it
    // An invalid changeset's save() skips the changes but still saves the model.
    if (changeset.isInvalid) throw new Error('Formwright: cannot save an invalid changeset')
    // save() applies the changes before the model saves. If that fails, take them back off
    // the model; they stay in the changeset, so the form still shows them. (The changeset's
    // own unexecute() skips accessors such as @tracked fields and record attributes.)
    const { data } = changeset
    const before = changeset.changes.map(
      ({ key }) => [key as string, pojoAdapter.get(data, key)] as const,
    )
    try {
      return await changeset.save()
    } catch (error) {
      for (const [key, value] of before) pojoAdapter.set(data, key, value)
      throw error
    }
  },
  rollback: changeset => {
    if (isChangeset(changeset)) changeset.rollback()
  },
  needsSave: changeset => isChangeset(changeset) && changeset.isDirty,
}

function isChangeset(model: object): model is ChangesetLike {
  const { rollback, validate } = model as Partial<ChangesetLike>
  return typeof rollback === 'function' && typeof validate === 'function'
}

/** A form `@validator` that runs the changeset's validations and shows them on their fields. */
export async function changesetValidator(changeset: ChangesetLike): Promise<ErrorMap> {
  await changeset.validate()
  const errors: ErrorMap = {}
  for (const { key, validation } of changeset.errors) {
    // A validation is a message, a list of them, or (from several validators) a list of lists.
    ;(errors[key] ??= []).push(...[validation].flat(2).map(String))
  }
  return errors
}
