import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@formwright/ember'

export class Person {
  @tracked name = ''
  @tracked email = ''
  @tracked password = ''
  @tracked website = ''
  @tracked phone = ''
  @tracked search = ''
  @tracked color = '#4f46e5'
  @tracked birthday = ''
  @tracked meeting = ''
  @tracked alarm = ''
}

export const createModel = () => new Person()

const TextControls: TOC<{ Args: { model: Person } }> = <template>
  <Form @model={{@model}} @name="person" as |f|>
    <div class="grid-2">
      <f.Field @for="name" @label="input (default)" @placeholder="Ada Lovelace" />
      <f.Field @for="email" @control="email" @label="email" />
      <f.Field @for="password" @control="password" @label="password" />
      <f.Field @for="website" @control="url" @label="url" @placeholder="https://" />
      <f.Field @for="phone" @control="tel" @label="tel" />
      <f.Field @for="search" @control="search" @label="search" />
      <f.Field @for="birthday" @control="date" @label="date" />
      <f.Field @for="meeting" @control="datetime" @label="datetime" />
      <f.Field @for="alarm" @control="time" @label="time" />
      <f.Field @for="color" @control="color" @label="color" />
    </div>
  </Form>
</template>

export default TextControls
