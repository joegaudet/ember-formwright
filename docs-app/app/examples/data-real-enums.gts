import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { array } from '@ember/helper'
import { Form } from '@formwright/ember'
import { enumOptions, enumValue } from '@formwright/real-enums'

// Stands in for `import { Enum } from 'real-enums'` until real-enums 2 is on npm:
// the same shape, a String subclass with `values`, `value` and `label`.
class Enum extends String {
  constructor(readonly value: string) {
    super(value)
  }
  get label() {
    return this.value.charAt(0).toUpperCase() + this.value.slice(1)
  }
  static get values(): any[] {
    return Object.values(this).filter(member => member instanceof this)
  }
}

export class OrderState extends Enum {
  static Pending = new OrderState('pending')
  static Shipped = new OrderState('shipped')
  static Delivered = new OrderState('delivered')
  static Cancelled = new OrderState('cancelled')
}

export class Order {
  /** Holds the enum member itself. */
  @tracked state: OrderState = OrderState.Pending
  /** Holds the raw string, as an API would send it. */
  @tracked nextState = 'shipped'
}

export const createModel = () => new Order()

const OrderForm: TOC<{ Args: { model: Order } }> = <template>
  <Form @model={{@model}} @name="order" as |f|>
    <f.Field @for="state" @control="select" @label="State" @options={{enumOptions OrderState}} />
    <f.Field
      @for="nextState"
      @control="radio"
      @label="Move to"
      @options={{enumOptions OrderState except=(array OrderState.Pending)}}
      @optionKey={{enumValue}}
      @storeKey={{true}}
    />
  </Form>
</template>

export default OrderForm
