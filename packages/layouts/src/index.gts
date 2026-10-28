import type { TOC } from '@ember/component/template-only'
import { registerLayout, type FieldLayoutSignature } from '@ember-formwright/ember'

/*
 * Each layout places the parts a field gives it (see FieldLayoutParts in the core). The parts
 * own their ids, aria-* and data-test-fw-* attributes, so a layout only decides structure.
 * A group control's <legend> stays the first child of its <fieldset>: `Label` is always the
 * first thing inside `Group`.
 */

/** The label in a column on the left; control, hint and errors on the right. */
export const Horizontal: TOC<FieldLayoutSignature> = <template>
  <@parts.Group>
    <@parts.Label class="fw-horizontal-label" />
    <div class="fw-horizontal-body">
      <@parts.Control as |control|>{{yield control}}</@parts.Control>
      <@parts.Hint />
      <@parts.Errors />
    </div>
  </@parts.Group>
</template>

/** Label and control on one line, for filter bars and settings rows; hint and errors below. */
export const Compact: TOC<FieldLayoutSignature> = <template>
  <@parts.Group>
    <@parts.Label />
    <@parts.Control as |control|>{{yield control}}</@parts.Control>
    <@parts.Hint />
    <@parts.Errors class="fw-compact-errors" />
  </@parts.Group>
</template>

/**
 * The control, then its label: the usual order for a single checkbox. A group keeps its
 * legend first, as a fieldset needs.
 */
export const CheckboxAfter: TOC<FieldLayoutSignature> = <template>
  {{#if @field.isGroup}}
    <@parts.Group>
      <@parts.Label />
      <@parts.Hint />
      <@parts.Control as |control|>{{yield control}}</@parts.Control>
      <@parts.Errors />
    </@parts.Group>
  {{else}}
    <@parts.Control as |control|>{{yield control}}</@parts.Control>
    <@parts.Label class="fw-checkbox-after-label" />
    <@parts.Hint />
    <@parts.Errors />
  {{/if}}
</template>

interface ActionsSignature {
  Element: HTMLDivElement
  Blocks: {
    /** Buttons on the start side, e.g. `<f.Submit>` and `<f.Reset>`. */
    left: []
    /** Buttons on the end side, e.g. a destructive `<f.Button>`. */
    right: []
  }
}

/** A bar for a form's buttons, with `left` and `right` slots. */
export const Actions: TOC<ActionsSignature> = <template>
  <div class="fw-actions" ...attributes>
    <div class="fw-actions-left">{{yield to="left"}}</div>
    <div class="fw-actions-right">{{yield to="right"}}</div>
  </div>
</template>

/**
 * Makes `@layout="horizontal"`, `"compact"` and `"checkbox-after"` available to every form.
 * Call once, e.g. in app.ts.
 */
export function registerLayouts(): void {
  registerLayout('horizontal', Horizontal)
  registerLayout('compact', Compact)
  registerLayout('checkbox-after', CheckboxAfter)
}
