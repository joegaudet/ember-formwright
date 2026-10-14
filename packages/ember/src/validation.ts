import type { StandardSchemaV1 } from '@standard-schema/spec'
import { normalizePath } from './path.ts'

/** Error messages by field path. The empty path `''` holds form-level errors. */
export type ErrorMap = Record<string, string[]>

export type ValidatorFn<M> = (model: M) => ErrorMap | undefined | Promise<ErrorMap | undefined>

/** Any Standard Schema (zod, valibot, arktype, ...) or a function returning an ErrorMap. */
export type Validator<M = any> = StandardSchemaV1 | ValidatorFn<M>

function isStandardSchema(v: unknown): v is StandardSchemaV1 {
  return typeof v === 'object' && v !== null && '~standard' in v
}

export async function runValidator<M>(
  validator: Validator<M> | undefined,
  model: M,
): Promise<ErrorMap> {
  if (!validator) return {}
  if (!isStandardSchema(validator)) return (await validator(model)) ?? {}

  const result = await validator['~standard'].validate(model)
  const errors: ErrorMap = {}
  for (const issue of result.issues ?? []) {
    const path = issue.path ? normalizePath(issue.path) : ''
    ;(errors[path] ??= []).push(issue.message)
  }
  return errors
}

export function hasErrors(errors: ErrorMap): boolean {
  return Object.values(errors).some(messages => messages.length > 0)
}
