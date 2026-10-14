import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { Form } from '@formwright/ember'

export class Shipment {
  @tracked carrier = 'Canada Post'
  @tracked tracking = 'CA123456789'
}

export const createModel = () => new Shipment()

type Mode = 'editable' | 'disabled' | 'readonly'
const MODES: Mode[] = ['editable', 'disabled', 'readonly']
const CARRIERS = ['Canada Post', 'UPS', 'DHL']

export default class ShipmentForm extends Component<{ Args: { model: Shipment } }> {
  @tracked mode: Mode = 'editable'

  setMode = (event: Event) => (this.mode = (event.target as HTMLInputElement).value as Mode)
  is = (mode: Mode) => this.mode === mode

  <template>
    <fieldset class="mode-switch">
      <legend>Form mode</legend>
      {{#each MODES as |mode|}}
        <label>
          <input
            type="radio"
            name="mode"
            value={{mode}}
            checked={{this.is mode}}
            {{on "change" this.setMode}}
          />
          {{mode}}
        </label>
      {{/each}}
    </fieldset>

    <Form
      @model={{@model}}
      @name="shipment"
      @disabled={{this.is "disabled"}}
      @readonly={{this.is "readonly"}}
      as |f|
    >
      <f.Field @for="carrier" @control="select" @label="Carrier" @options={{CARRIERS}} />
      <f.Field @for="tracking" @label="Tracking number" />
    </Form>
  </template>
}
