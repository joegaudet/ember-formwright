import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerMaskedControl } from '@ember-formwright/maskito'

// Once, at boot (e.g. app/app.ts): makes @control="masked" available.
registerMaskedControl()

const phoneMask = {
  mask: ['(', /\d/, /\d/, /\d/, ')', ' ', /\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, /\d/],
}
const postalMask = { mask: [/[A-Za-z]/, /\d/, /[A-Za-z]/, ' ', /\d/, /[A-Za-z]/, /\d/] }

export class Address {
  @tracked phone = ''
  @tracked postalCode = ''
}

export const createModel = () => new Address()

const AddressForm: TOC<{ Args: { model: Address } }> = <template>
  <Form @model={{@model}} @name="address" as |f|>
    <f.Field @for="phone" @control="masked" @label="Phone" as |field|>
      <field.Control @mask={{phoneMask}} @placeholder="(555) 555-5555" />
    </f.Field>
    <f.Field @for="postalCode" @control="masked" @label="Postal code" as |field|>
      <field.Control @mask={{postalMask}} @placeholder="K1A 0B1" />
    </f.Field>
  </Form>
</template>

export default AddressForm
