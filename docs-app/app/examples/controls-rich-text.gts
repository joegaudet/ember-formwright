import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerTiptapControl } from '@ember-formwright/tiptap'

// Once, at boot (e.g. app/app.ts): @control="rich-text".
registerTiptapControl()

export class Post {
  @tracked title = 'Release notes'
  /** Stores HTML. */
  @tracked body =
    '<h2>What is new</h2>' +
    '<p>Four new controls, each in its <strong>own package</strong>, so you install only ' +
    'what you <em>use</em>:</p>' +
    '<ul><li><p>Date pickers</p></li><li><p>Phone numbers</p></li>' +
    '<li><p>File uploads</p></li><li><p>Rich text</p></li></ul>'
}

export const createModel = () => new Post()

const PostForm: TOC<{ Args: { model: Post } }> = <template>
  <Form @model={{@model}} @name="post" as |f|>
    <f.Field @for="title" @label="Title" />
    <f.Field
      @for="body"
      @control="rich-text"
      @label="Body"
      @hint="Markdown shortcuts work too: ## for a heading, - for a list"
      @placeholder="Write something"
    />
  </Form>
</template>

export default PostForm
