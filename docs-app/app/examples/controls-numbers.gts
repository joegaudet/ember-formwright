import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'

export class Order {
  @tracked quantity: number | null = 2
  @tracked volume: number | null = 60
  @tracked total: number | null = 1499.5
}

export const createModel = () => new Order()

const NumberControls: TOC<{ Args: { model: Order } }> = <template>
  <Form @model={{@model}} @name="order" as |f|>
    <f.Field @for="quantity" @control="number" @label="number" @min={{1}} @max={{10}} />
    <f.Field @for="volume" @control="range" @label="range" @min={{0}} @max={{100}} @step={{5}} />
    <f.Field
      @for="total"
      @control="currency"
      @label="currency (EUR, de-DE)"
      @currency="EUR"
      @locale="de-DE"
    />
  </Form>
</template>

export default NumberControls
