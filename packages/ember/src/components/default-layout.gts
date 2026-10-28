import type { TOC } from '@ember/component/template-only'
import type { FieldLayoutSignature } from '../layout.ts'

/** Label, hint, control, errors; in a fieldset for a group. Formwright's markup since 1.0. */
const DefaultLayout: TOC<FieldLayoutSignature> = <template>
  <@parts.Group>
    <@parts.Label />
    <@parts.Hint />
    <@parts.Control as |control|>{{yield control}}</@parts.Control>
    <@parts.Errors />
  </@parts.Group>
</template>

export default DefaultLayout
