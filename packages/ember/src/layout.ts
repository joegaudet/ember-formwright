import type { ComponentLike } from '@glint/template'
import type { ControlSignature } from './controls/signature.ts'
import DefaultLayout from './components/default-layout.gts'

/**
 * The control yielded by a field's block, with the field's wiring already bound: any of its
 * args can still be passed, e.g. ones the field doesn't take (`@mask`). Typed by the field's
 * control; a layout sees it loosely.
 */
export type BoundControl<S = ControlSignature<any, any>> = ComponentLike<{
  Element: S extends { Element: infer E } ? E : null
  Args: Partial<S extends { Args: infer A } ? A : never>
}>

/** What a field's block receives (and what a layout passes on to it). */
export interface FieldBlockParams<V = unknown, C extends BoundControl<any> = BoundControl> {
  Control: C
  id: string
  value: V
  errors: string[]
  isInvalid: boolean
}

/** A field's state, for a layout to read. */
export interface FieldLayoutState {
  readonly id: string
  readonly controlName: string
  /** The control is a group (radio, checkbox-group): `Group` renders a fieldset. */
  readonly isGroup: boolean
  readonly isInvalid: boolean
  readonly isDirty: boolean
  readonly disabled: boolean
  readonly required: boolean
}

/**
 * The parts of a field, already wired: each owns its ids, `aria-*` and `data-test-fw-*`
 * attributes. A layout places them, and can add attributes (a class) to all but `Control`.
 */
export interface FieldLayoutParts {
  /** `<label for>`, or the `<legend>` of a group. Nothing without `@label`. */
  Label: ComponentLike<{ Element: HTMLLabelElement | HTMLLegendElement }>
  /** The hint, with the id the control's `aria-describedby` points at. Nothing without `@hint`. */
  Hint: ComponentLike<{ Element: HTMLParagraphElement }>
  /**
   * Everything about the control: the inline value, the callout, the control, ✔ and ✘. Render
   * it as `<@parts.Control as |control|>{{yield control}}</@parts.Control>`, which passes a
   * field's block on to it.
   */
  Control: ComponentLike<{ Blocks: { default: [FieldBlockParams] } }>
  /** The aria-live error region, with its own id. Always rendered. */
  Errors: ComponentLike<{ Element: HTMLDivElement }>
  /** A group control's `<fieldset>`, whose first child must be the `Label`; otherwise nothing. */
  Group: ComponentLike<{ Element: HTMLFieldSetElement; Blocks: { default: [] } }>
}

export interface FieldLayoutSignature {
  Args: {
    parts: FieldLayoutParts
    field: FieldLayoutState
  }
  Blocks: { default: [FieldBlockParams] }
}

/** Arranges a field's parts inside its `div.fw-field`. */
export type FieldLayout = ComponentLike<FieldLayoutSignature>

const layouts = new Map<string, FieldLayout>([['default', DefaultLayout]])
let defaultLayout: string | FieldLayout = 'default'

/** Makes a layout available to every form as `@layout="<name>"`. */
export function registerLayout(name: string, layout: FieldLayout): void {
  layouts.set(name, layout)
}

export function lookupLayout(name: string): FieldLayout {
  const layout = layouts.get(name)
  if (!layout) {
    throw new Error(
      `Unknown Formwright layout "${name}". Pass a component to @layout, or register it with registerLayout('${name}', Component). Known layouts: ${[...layouts.keys()].join(', ')}`,
    )
  }
  return layout
}

/** A layout name or component, as a component. */
export function resolveLayout(layout: string | FieldLayout): FieldLayout {
  return typeof layout === 'string' ? lookupLayout(layout) : layout
}

/** Sets the layout fields use when neither they nor their form has `@layout`. Call it at boot. */
export function setDefaultLayout(layout: string | FieldLayout): void {
  if (typeof layout === 'string') lookupLayout(layout)
  defaultLayout = layout
}

export function getDefaultLayout(): FieldLayout {
  return resolveLayout(defaultLayout)
}
