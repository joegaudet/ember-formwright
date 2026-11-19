import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form, type ErrorMap } from '@ember-formwright/ember'

const MEALS = [
  { id: 'fish', label: 'Fish' },
  { id: 'veg', label: 'Vegetarian' },
]

export class Rsvp {
  @tracked name = ''
  @tracked meal: string | null = null
}

export const createModel = () => new Rsvp()

function validate(rsvp: Rsvp): ErrorMap<Rsvp> {
  const errors: ErrorMap<Rsvp> = {}
  if (!rsvp.name) errors['name'] = ['Please enter your name']
  if (!rsvp.meal) errors['meal'] = ['Please pick a meal']
  return errors
}

/** Send it empty: focus moves to Name, and each error is announced. */
const RsvpForm: TOC<{ Args: { model: Rsvp } }> = <template>
  <Form @model={{@model}} @name="rsvp" @validator={{validate}} as |f|>
    <f.Field @for="name" @label="Name" @hint="As it appears on your ticket." @required={{true}} />
    <f.Field
      @for="meal"
      @control="radio"
      @label="Meal"
      @options={{MEALS}}
      @storeKey={{true}}
      @required={{true}}
    />
    <f.Submit>Send RSVP</f.Submit>
  </Form>
</template>

export default RsvpForm
