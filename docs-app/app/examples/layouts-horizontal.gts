import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerLayouts } from '@ember-formwright/layouts'

// Once, at boot (e.g. app/app.ts): @layout="horizontal", "compact" and "checkbox-after".
registerLayouts()

const ROLES = [
  { id: 'admin', label: 'Admin' },
  { id: 'editor', label: 'Editor' },
  { id: 'viewer', label: 'Viewer' },
]

export class Member {
  @tracked name = 'Ada Lovelace'
  @tracked email = ''
  @tracked role = 'editor'
}

export const createModel = () => new Member()

const MemberForm: TOC<{ Args: { model: Member } }> = <template>
  <Form @model={{@model}} @name="member" @layout="horizontal" as |f|>
    <f.Field @for="name" @label="Name" @required={{true}} />
    <f.Field @for="email" @control="email" @label="Email" @hint="Where invites go" />
    <f.Field @for="role" @control="radio" @label="Role" @options={{ROLES}} @storeKey={{true}} />
  </Form>
</template>

export default MemberForm
