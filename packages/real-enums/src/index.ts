/**
 * The parts of a real-enums class this package reads: `Enum.values` (every member, in
 * declaration order) and, on each member, `value` and `label`. Formwright's controls
 * already understand real-enums members as options; these helpers cover the rest.
 */
export interface EnumLike {
  readonly values: ReadonlyArray<EnumMember>
}

/** One member of a real-enums class: its raw `value` and its display `label`. */
export interface EnumMember {
  readonly value: string
  readonly label: string
}

/** Narrows {@link enumOptions}: keep `only` these members, or all `except` these. */
export interface EnumOptionsFilter<M extends EnumMember> {
  /** Keep just these members, in the enum's order. */
  only?: readonly M[]
  /** Leave these members out. */
  except?: readonly M[]
}

/**
 * The enum's members as `@options`, optionally filtered:
 *
 *   <f.Field @for="state" @control="select" @options={{enumOptions OrderState}} />
 *   <f.Field @for="state" @control="radio" @options={{enumOptions OrderState except=(array OrderState.Cancelled)}} />
 */
export function enumOptions<M extends EnumMember>(
  Enum: { readonly values: ReadonlyArray<M> },
  filter: EnumOptionsFilter<M> = {},
): M[] {
  const has = (list: readonly M[], m: M) => list.some(x => x.value === m.value)
  return Enum.values.filter(
    m => (!filter.only || has(filter.only, m)) && !(filter.except && has(filter.except, m)),
  )
}

/**
 * `@optionKey` for models that store the raw string (`order.state === 'shipped'`) rather
 * than the enum member. Pair it with `@storeKey={{true}}`.
 */
export const enumValue = (member: EnumMember): string => member.value

/** `@format` for inline editing: shows the member's label for a raw value or a member. */
export function enumLabel(Enum: EnumLike): (value: unknown) => string {
  return value => Enum.values.find(m => m.value === String(value))?.label ?? ''
}
