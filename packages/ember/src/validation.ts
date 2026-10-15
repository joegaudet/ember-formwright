import type { StandardSchemaV1 } from '@standard-schema/spec'
import { normalizePath, type Path } from './path.ts'

/**
 * Error messages by field path. The empty path `''` holds form-level errors. Keys are checked
 * against the model's paths; a loosely typed model (or a bare `ErrorMap`) takes any string.
 */
export type ErrorMap<M = any> =
  string extends Path<M> ? Record<string, string[]> : { [P in Path<M> | '']?: string[] }

/** Any ErrorMap, whatever its model. */
export type AnyErrorMap = { [path: string]: string[] | undefined }

/** An empty map is valid for every model; TypeScript can't see that through ErrorMap<M>. */
export const noErrors = <M>() => ({}) as ErrorMap<M>

export type ValidatorFn<M> = (
  model: M,
) => ErrorMap<M> | undefined | Promise<ErrorMap<M> | undefined>

/** Any Standard Schema (zod, valibot, arktype, ...) or a function returning an ErrorMap. */
export type Validator<M = any> = StandardSchemaV1 | ValidatorFn<M>

function isStandardSchema(v: unknown): v is StandardSchemaV1 {
  return typeof v === 'object' && v !== null && '~standard' in v
}

export async function runValidator<M>(
  validator: Validator<M> | undefined,
  model: M,
): Promise<ErrorMap<M>> {
  if (!validator) return noErrors()
  if (!isStandardSchema(validator)) return (await validator(model)) ?? noErrors()

  const result = await validator['~standard'].validate(model)
  const errors: Record<string, string[]> = {}
  for (const issue of result.issues ?? []) {
    const path = issue.path ? normalizePath(issue.path) : ''
    ;(errors[path] ??= []).push(issue.message)
  }
  // A schema's issue paths come from the schema, which TypeScript can't relate to the model.
  return errors as ErrorMap<M>
}

export function hasErrors(errors: AnyErrorMap): boolean {
  return Object.values(errors).some(messages => Boolean(messages?.length))
}
