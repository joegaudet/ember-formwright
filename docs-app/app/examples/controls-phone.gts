import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { isValidPhone, registerPhoneControl } from '@ember-formwright/maskito/phone'
import { z } from 'zod'

// Once, at boot (e.g. app/app.ts): makes @control="phone" available.
registerPhoneControl()

export class Contact {
  /** Stored in E.164 form; shown formatted. */
  @tracked phone: string | null = '+12125550123'
  @tracked mobile: string | null = null
  @tracked office: string | null = null
}

export const createModel = () => new Contact()

const phone = z.string().nullable()
const schema = z.object({
  phone: phone.refine(v => isValidPhone(v), 'That number looks off'),
  // Optional: only a number that was typed has to be valid.
  mobile: phone.refine(v => v === null || isValidPhone(v), 'That number looks off'),
  office: phone.refine(v => v === null || isValidPhone(v), 'That number looks off'),
})

const ContactForm: TOC<{ Args: { model: Contact } }> = <template>
  <Form @model={{@model}} @name="contact" @validator={{schema}} as |f|>
    <f.Field @for="phone" @control="phone" @label="Phone" @required={{true}} />
    <f.Field @for="mobile" @control="phone" @label="UK mobile" as |field|>
      <field.Control @country="GB" @placeholder="+44 7700 900123" />
    </f.Field>
    <f.Field
      @for="office"
      @control="phone"
      @label="Office"
      @hint="Any country: start with +"
      as |field|
    >
      <field.Control @strict={{false}} @placeholder="+33 6 12-34-56-78" />
    </f.Field>
    <f.Submit>Save</f.Submit>
  </Form>
</template>

export default ContactForm
