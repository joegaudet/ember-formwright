import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@formwright/ember'

export class Newsletter {
  @tracked email = ''
  @tracked frequency = 'weekly'
}

export const createModel = () => new Newsletter()

const FREQUENCIES = ['daily', 'weekly', 'monthly']

/** Theming is custom properties. Scope them to any element, here a class. */
const NewsletterForm: TOC<{ Args: { model: Newsletter } }> = <template>
  <div class="sunset">
    <Form @model={{@model}} @name="newsletter" as |f|>
      <f.Field @for="email" @control="email" @label="Email" @placeholder="you@example.com" />
      <f.Field @for="frequency" @control="radio" @label="How often?" @options={{FREQUENCIES}} />
      <f.Submit>Subscribe</f.Submit>
    </Form>
  </div>

  <style>
    .sunset {
      --fw-accent: #ea580c;
      --fw-border-focus: #ea580c;
      --fw-radius: 14px;
      --fw-border: #fed7aa;
      --fw-field-gap: 1rem;
    }
    .sunset .fw-label {
      text-transform: uppercase;
      letter-spacing: 0.08em;
      font-size: 0.75rem;
    }
  </style>
</template>

export default NewsletterForm
