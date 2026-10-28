import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerFileUploadControls } from '@ember-formwright/file-upload'

// Once, at boot (e.g. app/app.ts): @control="file" and @control="files".
registerFileUploadControls()

/** A stand-in for a file the user picked earlier. */
const sample = (name: string, bytes: number, type: string) =>
  new File([new Uint8Array(bytes)], name, { type })

export class JobApplication {
  /** `file` stores one File (or null). */
  @tracked resume: File | null = sample('ada-lovelace-cv.pdf', 184_320, 'application/pdf')
  /** `files` stores an array of them. */
  @tracked samples: File[] = [
    sample('analytical-engine.png', 1_240_000, 'image/png'),
    sample('note-g.pdf', 96_400, 'application/pdf'),
  ]
}

export const createModel = () => new JobApplication()

const ApplicationForm: TOC<{ Args: { model: JobApplication } }> = <template>
  <Form @model={{@model}} @name="application" as |f|>
    <f.Field @for="resume" @control="file" @label="Résumé" @hint="A PDF, up to 5 MB" as |field|>
      <field.Control @accept=".pdf" />
    </f.Field>

    <f.Field @for="samples" @control="files" @label="Work samples" as |field|>
      <field.Control @accept="image/*,.pdf" />
    </f.Field>
  </Form>
</template>

export default ApplicationForm
