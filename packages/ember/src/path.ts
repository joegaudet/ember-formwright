/**
 * Normalizes a property path so `items[0].name`, `items.0.name` and ` items.0.name `
 * all address (and select) the same field.
 */
export function normalizePath(
  path: string | number | ReadonlyArray<PropertyKey | { key: PropertyKey }>,
): string {
  if (Array.isArray(path)) {
    return path
      .map(segment => (typeof segment === 'object' && segment !== null ? segment.key : segment))
      .map(String)
      .join('.')
  }
  return String(path)
    .trim()
    .replace(/\[(\w+)\]/g, '.$1')
    .replace(/^\./, '')
}
