import Component from '@glimmer/component'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import { Maskito, type MaskitoOptions } from '@maskito/core'
import { registerControl, type ControlSignature } from '@ember-formwright/ember'

interface MaskedSignature {
  Element: HTMLInputElement
  Args: ControlSignature<string>['Args'] & {
    /** Any Maskito options, e.g. from `@maskito/kit`'s maskitoNumberOptionsGenerator. */
    mask?: MaskitoOptions
  }
}

/**
 * A text input with a Maskito mask. Pass the mask through the field's yielded Control:
 *
 *   <f.Field @for="phone" @control="masked" @label="Phone" as |field|>
 *     <field.Control @mask={{phoneMask}} />
 *   </f.Field>
 */
export default class Masked extends Component<MaskedSignature> {
  mask = modifier((element: HTMLInputElement, [options]: [MaskitoOptions | undefined]) => {
    if (!options) return
    const maskito = new Maskito(element, options)
    return () => maskito.destroy()
  })

  onInput = (event: Event) => this.args.onChange((event.target as HTMLInputElement).value)

  <template>
    <input
      id={{@id}}
      name={{@name}}
      class="fw-control fw-input fw-masked"
      type="text"
      value={{@value}}
      placeholder={{@placeholder}}
      disabled={{@disabled}}
      readonly={{@readonly}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
      {{this.mask @mask}}
      {{on "input" this.onInput}}
    />
  </template>
}

/** Makes `@control="masked"` available to every form. Call once, e.g. in app.ts. */
export function registerMaskedControl(name = 'masked'): void {
  registerControl(name, Masked)
}

export { Masked }
