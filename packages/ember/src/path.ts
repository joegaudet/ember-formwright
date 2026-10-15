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

/**
 * The paths a key `K` holding `V` contributes; arrays are indexed as `k.0` or `k[0]`. Written
 * out rather than through a helper alias, so type errors list the paths themselves.
 */
type KeyPaths<K extends string, V, D extends number> = 0 extends 1 & V
  ? K | `${K}.${string}`
  : V extends readonly (infer E)[]
    ? | K
      | `${K}.${number}`
      | `${K}[${number}]`
      | `${K}.${number}.${PathsOf<E, Depth[D]>}`
      | `${K}[${number}].${PathsOf<E, Depth[D]>}`
    : K | `${K}.${PathsOf<V, Depth[D]>}`

type PathsOf<T, D extends number> = [D] extends [never]
  ? never
  : T extends Leaf
    ? never
    : T extends readonly (infer E)[]
      ? `${number}` | `${number}.${PathsOf<E, Depth[D]>}`
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

/** `items[0].name` → `items.0.name`, as `normalizePath` does at runtime. */
type Dotted<P extends string> = P extends `${infer Head}[${infer Index}]${infer Rest}`
  ? Dotted<`${Head}.${Index}${Rest}`>
  : P

/** One step down: a key of an object or an index of an array. Missing parents read as undefined. */
type Step<T, K extends string> = T extends null | undefined
  ? undefined
  : T extends readonly (infer E)[]
    ? K extends `${number}`
      ? E
      : never
    : K extends keyof T
      ? T[K]
      : never

type ValueAt<T, P extends string> = P extends `${infer K}.${infer Rest}`
  ? ValueAt<Step<T, K>, Rest>
  : Step<T, P>

/**
 * The type of the value at `path` in `M`: `PathValue<Account, 'address.city'>` is `string`.
 * Loose models (where `Path<M>` is `string`) give `unknown`.
 */
export type PathValue<M, P extends string> = 0 extends 1 & M
  ? any
  : string extends P
    ? unknown
    : ValueAt<M, Dotted<P>>
