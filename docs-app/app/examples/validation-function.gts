import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form, type ErrorMap } from '@ember-formwright/ember'

const TAKEN = ['ada', 'grace', 'admin']

export class Handle {
  @tracked username = ''
  @tracked agree = false
}

export const createModel = () => new Handle()

/**
 * A validator can be a (possibly async) function returning messages by path.
 * The empty path '' holds form-level errors, shown by <f.Errors />. ErrorMap<Handle> only
 * accepts Handle's paths, so a misspelled key is a type error.
 */
async function validate(handle: Handle): Promise<ErrorMap<Handle>> {
  const errors: ErrorMap<Handle> = {}
  if (!handle.username) errors['username'] = ['Pick a username']
  // Pretend this asks the server.
  await new Promise(resolve => setTimeout(resolve, 150))
  if (TAKEN.includes(handle.username.toLowerCase())) errors['username'] = ['That username is taken']
  if (!handle.agree) errors[''] = ['Please accept the code of conduct to continue.']
  return errors
}

const HandleForm: TOC<{ Args: { model: Handle } }> = <template>
  <Form @model={{@model}} @name="handle" @validator={{validate}} as |f|>
    <f.Errors />
    <f.Field @for="username" @label="Username" @hint="Try “ada”." />
    <f.Field @for="agree" @control="checkbox" @label="I accept the code of conduct" />
    <f.Submit>Claim username</f.Submit>
  </Form>
</template>

export default HandleForm
