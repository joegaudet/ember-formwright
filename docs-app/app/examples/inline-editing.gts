import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@formwright/ember'

export class Contact {
  @tracked name = 'Grace Hopper'
  @tracked title = 'Rear Admiral'
  @tracked phone = ''
}

export const createModel = () => new Contact()

const ContactCard: TOC<{ Args: { model: Contact } }> = <template>
  <h4>Inline</h4>
  <Form @model={{@model}} @name="inline" @inline={{true}} as |f|>
    <f.Field @for="name" @label="Name" />
    <f.Field @for="title" @label="Title" />
  </Form>

  <h4>In a popover</h4>
  <Form @model={{@model}} @name="callout" @inline={{true}} @callout={{true}} as |f|>
    <f.Field @for="phone" @control="tel" @label="Phone" @placeholder="Add a phone number" />
  </Form>
</template>

export default ContactCard
