import type { ErrorMap, ModelAdapter } from '@ember-formwright/ember'

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
}

/**
 * Lets Formwright forms edit an ember-changeset changeset:
 *
 * - edits stay in the changeset; the model underneath changes only on submit
 * - submit calls `changeset.save()`, which applies the changes and saves the model
 * - reset calls `changeset.rollback()`
 * - nested forms save their changeset when it is dirty
 *
 * Pair it with `changesetValidator` to run the changeset's validations when the form validates.
 */
export const changesetAdapter: ModelAdapter<ChangesetLike> = {
  get: (changeset, path) => changeset.get(path),
  set: (changeset, path, value) => {
    changeset.set(path, value)
  },
  save(changeset) {
    // An invalid changeset's save() skips the changes but still saves the model.
    if (changeset.isInvalid) throw new Error('Formwright: cannot save an invalid changeset')
    return changeset.save()
  },
  rollback: changeset => {
    changeset.rollback()
  },
  needsSave: changeset => changeset.isDirty,
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
