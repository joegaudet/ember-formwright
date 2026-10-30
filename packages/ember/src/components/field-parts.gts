import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type Field from './field.gts'
import Errors from './errors.gts'
import type { FieldBlockParams } from '../layout.ts'

/*
 * The parts a layout arranges (see FieldLayoutParts). Each is bound to its field by the
 * field itself; a layout invokes them without args.
 */

interface PartSignature<E extends Element> {
  Element: E
  Args: { field: Field<any, any> }
}

/** `<label for>` the control, or a group's `<legend>`. */
export const FieldLabel: TOC<PartSignature<HTMLLabelElement | HTMLLegendElement>> = <template>
  {{#if @field.args.label}}
    {{#if @field.isGroup}}
      <legend class="fw-label" data-test-fw-label ...attributes>
        {{@field.args.label}}{{#if @field.args.required}}<span
            class="fw-required"
            aria-hidden="true"
          >*</span>{{/if}}
      </legend>
    {{else}}
      <label class="fw-label" for={{@field.id}} data-test-fw-label ...attributes>
        {{@field.args.label}}{{#if @field.args.required}}<span
            class="fw-required"
            aria-hidden="true"
          >*</span>{{/if}}
      </label>
    {{/if}}
  {{/if}}
</template>

export const FieldHint: TOC<PartSignature<HTMLParagraphElement>> = <template>
  {{#if @field.args.hint}}
    <p id={{@field.hintId}} class="fw-hint" data-test-fw-hint ...attributes>{{@field.args.hint}}</p>
  {{/if}}
</template>

export const FieldErrors: TOC<PartSignature<HTMLDivElement>> = <template>
  <Errors @id={{@field.errorsId}} @errors={{@field.errors}} ...attributes />
</template>

/** A group control's fieldset; its content as it is for any other control. */
export const FieldGroup: TOC<PartSignature<HTMLFieldSetElement> & { Blocks: { default: [] } }> =
  <template>
    {{#if @field.isGroup}}
      <fieldset class="fw-group" aria-describedby={{@field.describedBy}} ...attributes>
        {{yield}}
      </fieldset>
    {{else}}
      {{yield}}
    {{/if}}
  </template>

interface FieldControlSignature {
  Args: { field: Field<any, any>; hasBlock: boolean }
  Blocks: { default: [FieldBlockParams] }
}

/** The inline value, the control (optionally in a popover), and the confirm buttons. */
export const FieldControl: TOC<FieldControlSignature> = <template>
  {{#let @field as |field|}}
    {{#if field.showDisplay}}
      <button
        type="button"
        class="fw-display"
        style={{field.anchorStyle}}
        disabled={{field.disabled}}
        aria-expanded={{if field.isEditing "true" "false"}}
        data-fw-anchor={{field.id}}
        data-test-fw-display
        {{on "click" field.edit}}
      >
        {{#if field.displayValue}}
          {{field.displayValue}}
        {{else}}
          <span class="fw-placeholder">{{field.args.placeholder}}</span>
        {{/if}}
      </button>
    {{/if}}

    {{#if field.showControl}}
      <div
        class="fw-control-area{{if field.useCallout ' fw-callout'}}"
        popover={{if field.useCallout "auto"}}
        style={{if field.useCallout field.calloutStyle}}
        {{field.openPopover field.useCallout}}
        {{field.focusControl field.isEditing}}
        {{on "toggle" field.onCalloutToggle}}
      >
        {{#let
          (component
            field.control
            id=field.id
            name=field.fullPath
            type=field.controlName
            value=field.controlValue
            onChange=field.onChange
            disabled=field.disabled
            readonly=field.readonly
            required=field.args.required
            invalid=field.isInvalid
            describedBy=(if field.isGroup undefined field.describedBy)
            placeholder=field.args.placeholder
            label=field.args.label
            options=field.args.options
            optionKey=field.args.optionKey
            optionLabel=field.args.optionLabel
            storeKey=field.args.storeKey
            min=field.args.min
            max=field.args.max
            step=field.args.step
            maxLength=field.args.maxLength
            showCount=field.args.showCount
            currency=field.args.currency
            locale=field.args.locale
            callout=field.useCallout
          )
          as |Control|
        }}
          {{#if @hasBlock}}
            {{#if (has-block)}}
              {{yield
                (hash
                  Control=Control
                  id=field.id
                  value=field.controlValue
                  errors=field.errors
                  isInvalid=field.isInvalid
                )
              }}
            {{else}}
              {{! The layout didn't pass the field's block on: show the plain control. }}
              <Control />
            {{/if}}
          {{else}}
            <Control />
          {{/if}}
        {{/let}}

        {{#if field.showConfirm}}
          <span class="fw-confirm">
            <button
              type="button"
              class="fw-commit"
              aria-label="Apply"
              data-test-fw-commit
              {{on "click" field.commit}}
            ><svg class="fw-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path
                  d="M20 6 9 17l-5-5"
                /></svg></button>
            <button
              type="button"
              class="fw-cancel"
              aria-label="Cancel"
              data-test-fw-cancel
              {{on "click" field.cancel}}
            ><svg class="fw-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path
                  d="M18 6 6 18M6 6l12 12"
                /></svg></button>
          </span>
        {{/if}}
      </div>
    {{/if}}
  {{/let}}
</template>
