import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { z } from 'zod'

export class Registration {
  @tracked email = ''
  @tracked password = ''
  @tracked confirm = ''
  @tracked age: number | null = null
}

export const createModel = () => new Registration()

// Any Standard Schema validator works: zod, valibot, ArkType, ...
const schema = z
  .object({
    email: z.string().email('That email looks off'),
    password: z.string().min(8, 'Use at least 8 characters'),
    confirm: z.string(),
    age: z.number({ message: 'Enter your age' }).min(18, 'You must be 18 or older'),
  })
  // Issue paths decide which field shows the message. `when` runs the check even while
  // other fields still have issues (zod skips object refinements then, by default).
  .refine(r => r.password === r.confirm, {
    path: ['confirm'],
    message: 'Passwords must match',
    when: ({ value }) => typeof value === 'object' && value !== null,
  })

const RegistrationForm: TOC<{ Args: { model: Registration } }> = <template>
  <Form @model={{@model}} @name="registration" @validator={{schema}} as |f|>
    <f.Field @for="email" @control="email" @label="Email" />
    <f.Field @for="password" @control="password" @label="Password" />
    <f.Field @for="confirm" @control="password" @label="Confirm password" />
    <f.Field @for="age" @control="number" @label="Age" />
    <f.Submit>Create account</f.Submit>
  </Form>
</template>

export default RegistrationForm
