import { get } from '@ember/object'
import type { OptionAccessor } from './signature.ts'

function isObject(v: unknown): v is object {
  return typeof v === 'object' && v !== null
}

function read(option: unknown, accessor: OptionAccessor | undefined, fallbacks: string[]): unknown {
  if (typeof accessor === 'function') return accessor(option)
  if (!isObject(option)) return option
  if (accessor) return get(option, accessor)
  for (const key of fallbacks) if (key in option) return (option as Record<string, unknown>)[key]
  return option
}

/** The identity of an option: `optionKey`, else `id`, else `value` (real-enums), else itself. */
export function keyOf(option: unknown, accessor?: OptionAccessor): unknown {
  return read(option, accessor, ['id', 'value'])
}

export function labelOf(option: unknown, accessor?: OptionAccessor): string {
  return String(read(option, accessor, ['label', 'name']) ?? '')
}

/** Compares a stored value (an option, or just its key) with an option. */
export function matches(value: unknown, option: unknown, accessor?: OptionAccessor): boolean {
  if (value === null || value === undefined) return false
  return String(keyOf(value, accessor)) === String(keyOf(option, accessor))
}

export function toStored(
  option: unknown,
  storeKey: boolean | undefined,
  accessor?: OptionAccessor,
): unknown {
  return storeKey ? keyOf(option, accessor) : option
}

export function isDisabled(option: unknown): boolean {
  return isObject(option) && (option as { disabled?: unknown }).disabled === true
}
