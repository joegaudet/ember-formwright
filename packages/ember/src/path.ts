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

/** Remaining nesting levels; stops runaway recursion on deep or self-referencing models. */
type Depth = [never, 0, 1, 2, 3, 4]

/** Values whose own keys aren't model paths. */
type Leaf =
  | Date
  | RegExp
  | Promise<unknown>
  | Map<unknown, unknown>
  | Set<unknown>
  | WeakMap<object, unknown>
  | WeakSet<object>

/** `prefix`, plus every path inside `T` under it. */
type Under<Prefix extends string, T, D extends number> = Prefix | `${Prefix}.${PathsOf<T, D>}`

/** The paths a key `K` holding `V` contributes; arrays are indexed as `k.0` or `k[0]`. */
type KeyPaths<K extends string, V, D extends number> = 0 extends 1 & V
  ? K | `${K}.${string}`
  : V extends readonly (infer E)[]
    ? K | Under<`${K}.${number}` | `${K}[${number}]`, E, Depth[D]>
    : Under<K, V, Depth[D]>

type PathsOf<T, D extends number> = [D] extends [never]
  ? never
  : T extends Leaf
    ? never
    : T extends readonly (infer E)[]
      ? Under<`${number}`, E, Depth[D]>
      : T extends object
        ? {
            [K in keyof T & string]-?: NonNullable<T[K]> extends (...args: never[]) => unknown
              ? never
              : KeyPaths<K, NonNullable<T[K]>, D>
          }[keyof T & string]
        : never

/**
 * Every dotted path into `M` that a field can edit: `"name"`, `"address.city"`,
 * `"items.0.name"` or `"items[0].name"`. Methods are skipped and nesting stops at five
 * levels. Models typed loosely (`any`, `object`, or with an index signature) accept any string.
 */
export type Path<M> = 0 extends 1 & M
  ? string
  : [keyof M] extends [never]
    ? string
    : string extends keyof M
      ? string
      : PathsOf<M, 5>
