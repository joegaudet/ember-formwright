import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'

const TOPPINGS = [
  { id: 'basil', label: 'Basil' },
  { id: 'olives', label: 'Olives' },
  { id: 'chili', label: 'Chili' },
  { id: 'anchovies', label: 'Anchovies' },
]

export class Pizza {
  @tracked extraCheese = false
  @tracked toppings: string[] = ['basil']
}

export const createModel = () => new Pizza()

const PizzaForm: TOC<{ Args: { model: Pizza } }> = <template>
  <Form @model={{@model}} @name="pizza" as |f|>
    <f.Field @for="extraCheese" @control="checkbox" @label="Extra cheese" />
    <f.Field
      @for="toppings"
      @control="checkbox-group"
      @label="Toppings"
      @hint="Up to three."
      @options={{TOPPINGS}}
      @storeKey={{true}}
      @max={{3}}
    />
  </Form>
</template>

export default PizzaForm
