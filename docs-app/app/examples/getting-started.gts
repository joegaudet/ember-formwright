import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@formwright/ember'

export class Signup {
  @tracked name = ''
  @tracked email = ''
}

export const createModel = () => new Signup()

const SignupForm: TOC<{ Args: { model: Signup } }> = <template>
  <Form @model={{@model}} @name="signup" as |f|>
    <f.Field @for="name" @label="Your name" />
    <f.Field @for="email" @control="email" @label="Email" @hint="We never share it." />
    <f.Submit>Sign up</f.Submit>
  </Form>
</template>

export default SignupForm
