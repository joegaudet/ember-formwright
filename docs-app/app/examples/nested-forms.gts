import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form, type ErrorMap } from '@ember-formwright/ember'

/** Each model saves itself, the way an ember-data record would. */
class Saves {
  saved = 0
  save() {
    this.saved++
    return new Promise(resolve => setTimeout(resolve, 150))
  }
}

export class Warehouse extends Saves {
  @tracked city = 'Rotterdam'
}

export class Product extends Saves {
  @tracked name = ''
  @tracked sku = ''
  warehouse = new Warehouse()
}

export const createModel = () => new Product()

const productRules = (p: Product): ErrorMap => (p.name ? {} : { name: ['Name the product'] })
const warehouseRules = (w: Warehouse): ErrorMap =>
  w.city ? {} : { city: ['Where is it stocked?'] }

export default class ProductForm extends Component<{ Args: { model: Product } }> {
  @tracked log: string[] = []

  note = (entry: string) => (this.log = [...this.log, entry])
  productSaved = () => this.note('product saved')
  warehouseSaved = () => this.note('warehouse saved (after its parent)')

  <template>
    <Form
      @model={{@model}}
      @name="product"
      @validator={{productRules}}
      @didSubmit={{this.productSaved}}
      as |f|
    >
      <f.Field @for="name" @label="Product name" />
      <f.Field @for="sku" @label="SKU" />

      <f.Form
        @model={{@model.warehouse}}
        @name="warehouse"
        @legend="Warehouse"
        @validator={{warehouseRules}}
        @didSubmit={{this.warehouseSaved}}
        as |w|
      >
        <w.Field @for="city" @label="City" />
      </f.Form>

      <f.Submit>Save product</f.Submit>
    </Form>
    <ol class="hook-log" aria-label="Save order">
      {{#each this.log as |entry|}}<li>{{entry}}</li>{{/each}}
    </ol>
  </template>
}
