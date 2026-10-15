import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'

export class Tweet {
  @tracked text = ''
}

export const createModel = () => new Tweet()

const TweetForm: TOC<{ Args: { model: Tweet } }> = <template>
  <Form @model={{@model}} @name="tweet" as |f|>
    <f.Field @for="text" @control="textarea" @label="What's happening?" as |field|>
      <div class="composer">
        <field.Control @maxLength={{280}} @showCount={{true}} />
        <small class="composer-help" id="{{field.id}}-help">
          {{if field.isInvalid "Fix the errors below." "Markdown is not supported."}}
        </small>
      </div>
    </f.Field>
    <f.Submit>Post</f.Submit>
  </Form>
</template>

export default TweetForm
