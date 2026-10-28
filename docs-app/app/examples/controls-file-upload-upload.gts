import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerFileUploadControls, type UploadFn } from '@ember-formwright/file-upload'

registerFileUploadControls()

interface Attachment {
  id: number
  name: string
  url: string
}

let nextId = 1
const tick = () => new Promise(resolve => setTimeout(resolve, 60))

/**
 * Uploads a file and resolves with what to store. A real one would be
 * `const response = await file.upload('/api/uploads'); return response.json()`, and
 * ember-file-upload keeps `file.progress` up to date. This one pretends.
 */
const upload: UploadFn = async file => {
  for (let progress = 0; progress <= 100; progress += 20) {
    file.progress = progress
    await tick()
  }
  if (file.size > 1_000_000) throw new Error('Too large for this demo (1 MB at most)')
  const id = nextId++
  return { id, name: file.name, url: `/uploads/${id}/${file.name}` }
}

export class Message {
  /** What `upload` resolved to, one per file. */
  @tracked attachments: Attachment[] = []
}

export const createModel = () => new Message()

const MessageForm: TOC<{ Args: { model: Message } }> = <template>
  <Form @model={{@model}} @name="message" as |f|>
    <f.Field
      @for="attachments"
      @control="files"
      @label="Attachments"
      @hint="Uploaded as soon as you pick them"
      @optionLabel="name"
      as |field|
    >
      <field.Control @upload={{upload}} />
    </f.Field>
  </Form>
</template>

export default MessageForm
