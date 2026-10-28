import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import type { JSONContent } from '@tiptap/core'
import { Form } from '@ember-formwright/ember'
import { registerTiptapControl, toPlainText } from '@ember-formwright/tiptap'

registerTiptapControl()

export class Comment {
  /** Tiptap's JSON document, or null when empty. */
  @tracked body: JSONContent | null = null
}

export const createModel = () => new Comment()

const TOOLS = ['bold', 'italic', 'bullet-list'] as const

/** A comment needs some text. */
const validate = (comment: Comment) =>
  toPlainText(comment.body) ? {} : { body: ['Write a comment first'] }

const CommentForm: TOC<{ Args: { model: Comment } }> = <template>
  <Form @model={{@model}} @name="comment" @validator={{validate}} as |f|>
    <f.Field
      @for="body"
      @control="rich-text"
      @label="Comment"
      @placeholder="Leave a comment"
      @required={{true}}
      as |field|
    >
      <field.Control @toolbar={{TOOLS}} @output="json" />
    </f.Field>
    <f.Submit>Comment</f.Submit>
  </Form>
</template>

export default CommentForm
