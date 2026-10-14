/**
 * A plain-data copy of a model for the "model, live" panel. `@tracked` fields are accessors on
 * the prototype, which JSON.stringify skips, so getters up the prototype chain are read too.
 */
export function snapshot(value: unknown, seen = new WeakSet<object>()): unknown {
  if (value === null || typeof value !== 'object') return value
  if (value instanceof String) return value.valueOf() // real-enums members
  if (value instanceof Date) return value.toISOString()
  if (seen.has(value)) return '[circular]'
  seen.add(value)
  if (Array.isArray(value)) return value.map(v => snapshot(v, seen))

  const out: Record<string, unknown> = {}
  for (const key of Object.keys(value)) out[key] = snapshot((value as any)[key], seen)
  for (
    let proto = Object.getPrototypeOf(value);
    proto && proto !== Object.prototype;
    proto = Object.getPrototypeOf(proto)
  ) {
    for (const [key, descriptor] of Object.entries(Object.getOwnPropertyDescriptors(proto))) {
      if (key in out || key === 'constructor' || !descriptor.get) continue
      out[key] = snapshot((value as any)[key], seen)
    }
  }
  return out
}
