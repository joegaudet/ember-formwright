import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@formwright/ember'

const SPEEDS = [
  { id: 'standard', label: 'Standard (5–7 days)' },
  { id: 'express', label: 'Express (2 days)' },
  { id: 'overnight', label: 'Overnight', disabled: true },
]

export class Delivery {
  @tracked speed = 'standard'
}

export const createModel = () => new Delivery()

const DeliveryForm: TOC<{ Args: { model: Delivery } }> = <template>
  <Form @model={{@model}} @name="delivery" as |f|>
    <f.Field
      @for="speed"
      @control="radio"
      @label="Delivery speed"
      @options={{SPEEDS}}
      @storeKey={{true}}
    />
  </Form>
</template>

export default DeliveryForm
