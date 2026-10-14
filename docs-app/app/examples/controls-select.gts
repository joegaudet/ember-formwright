import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'

interface Country {
  code: string
  name: string
}

const COUNTRIES: Country[] = [
  { code: 'ca', name: 'Canada' },
  { code: 'jp', name: 'Japan' },
  { code: 'pt', name: 'Portugal' },
]
const SIZES = ['S', 'M', 'L', 'XL']
const PLANS = [
  { id: 'hobby', label: 'Hobby' },
  { id: 'team', label: 'Team' },
  { id: 'enterprise', label: 'Enterprise', disabled: true },
]

export class Checkout {
  /** Stores the whole option object. */
  @tracked country: Country | null = null
  /** Primitive options store themselves. */
  @tracked size = 'M'
  /** @storeKey stores just the option's key. */
  @tracked plan = 'team'
}

export const createModel = () => new Checkout()

const SelectControls: TOC<{ Args: { model: Checkout } }> = <template>
  <Form @model={{@model}} @name="checkout" as |f|>
    <f.Field
      @for="country"
      @control="select"
      @label="Country"
      @options={{COUNTRIES}}
      @optionKey="code"
      @optionLabel="name"
      @placeholder="Choose a country"
    />
    <f.Field @for="size" @control="select" @label="Size" @options={{SIZES}} />
    <f.Field @for="plan" @control="select" @label="Plan" @options={{PLANS}} @storeKey={{true}} />
  </Form>
</template>

export default SelectControls
