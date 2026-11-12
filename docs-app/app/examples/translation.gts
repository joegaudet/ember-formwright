import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerTiptapControl } from '@ember-formwright/tiptap'

registerTiptapControl()

export class Note {
  @tracked title = 'Notas da reunião'
  @tracked body = '<p>Próximos passos</p>'
}

export const createModel = () => new Note()

const toolbar = ['bold', 'italic'] as const
const toolLabels = { bold: 'Negrito', italic: 'Itálico' }

const NoteForm: TOC<{ Args: { model: Note } }> = <template>
  <Form @model={{@model}} @name="note" as |f|>
    <f.Field
      @for="title"
      @label="Título"
      @requireConfirm={{true}}
      @applyLabel="Aplicar"
      @cancelLabel="Cancelar"
    />
    <f.Field @for="body" @control="rich-text" @label="Texto" as |field|>
      <field.Control @toolbar={{toolbar}} @toolbarLabel="Formatação" @toolLabels={{toolLabels}} />
    </f.Field>
    <f.Submit @text="Guardar" />
    <f.Reset @text="Repor" />
  </Form>
</template>

export default NoteForm
