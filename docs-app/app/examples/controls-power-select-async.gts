import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerPowerSelectControls } from '@ember-formwright/power-select'

registerPowerSelectControls()

interface User {
  id: number
  name: string
}

const DIRECTORY: User[] = [
  { id: 1, name: 'Ada Lovelace' },
  { id: 2, name: 'Grace Hopper' },
  { id: 3, name: 'Alan Turing' },
  { id: 4, name: 'Katherine Johnson' },
  { id: 5, name: 'Margaret Hamilton' },
]

/** Stands in for a request to your API. */
async function searchUsers(term: string): Promise<User[]> {
  await new Promise(resolve => setTimeout(resolve, 150))
  return DIRECTORY.filter(u => u.name.toLowerCase().includes(term.toLowerCase()))
}

export class Project {
  @tracked lead: User | null = DIRECTORY[0]!
}

export const createModel = () => new Project()

/** Inline mode shows the value without the options, so say how to show it. */
const userName = (user: User | null) => user?.name ?? ''

const ProjectForm: TOC<{ Args: { model: Project } }> = <template>
  <Form @model={{@model}} @name="project" @inline={{true}} @callout={{true}} as |f|>
    <f.Field
      @for="lead"
      @control="power-select"
      @label="Lead"
      @placeholder="Nobody yet"
      @format={{userName}}
      @optionLabel="name"
      as |field|
    >
      <field.Control
        @search={{searchUsers}}
        @searchEnabled={{true}}
        @searchPlaceholder="Type a name"
      />
    </f.Field>
  </Form>
</template>

export default ProjectForm
