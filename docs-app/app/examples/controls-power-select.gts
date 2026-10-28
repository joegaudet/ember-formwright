import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerPowerSelectControls } from '@ember-formwright/power-select'

// Once, at boot (e.g. app/app.ts): @control="power-select" and "power-select-multiple".
registerPowerSelectControls()

interface User {
  id: number
  name: string
  email: string
}

const USERS: User[] = [
  { id: 1, name: 'Ada Lovelace', email: 'ada@example.com' },
  { id: 2, name: 'Grace Hopper', email: 'grace@example.com' },
  { id: 3, name: 'Alan Turing', email: 'alan@example.com' },
  { id: 4, name: 'Katherine Johnson', email: 'katherine@example.com' },
]

export class Ticket {
  /** Stores the chosen option. */
  @tracked owner: User | null = null
  /** A multiple select stores an array; with @storeKey, of ids. */
  @tracked watchers: number[] = [2]
}

export const createModel = () => new Ticket()

/** The option a block receives is loosely typed; say what it is. */
const asUser = (option: unknown) => option as User

const TicketForm: TOC<{ Args: { model: Ticket } }> = <template>
  <Form @model={{@model}} @name="ticket" as |f|>
    <f.Field
      @for="owner"
      @control="power-select"
      @label="Owner"
      @placeholder="Assign someone"
      @options={{USERS}}
      @optionLabel="name"
      as |field|
    >
      <field.Control @searchEnabled={{true}} @allowClear={{true}} as |option|>
        {{#let (asUser option) as |user|}}
          {{user.name}}
          <small>{{user.email}}</small>
        {{/let}}
      </field.Control>
    </f.Field>

    <f.Field
      @for="watchers"
      @control="power-select-multiple"
      @label="Watchers"
      @hint="Searchable; stores their ids"
      @options={{USERS}}
      @optionLabel="name"
      @storeKey={{true}}
      as |field|
    >
      <field.Control @searchEnabled={{true}} />
    </f.Field>
  </Form>
</template>

export default TicketForm
