import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@formwright/ember'

export class Review {
  @tracked body = ''
}

export const createModel = () => new Review()

const ReviewForm: TOC<{ Args: { model: Review } }> = <template>
  <Form @model={{@model}} @name="review" as |f|>
    <f.Field
      @for="body"
      @control="textarea"
      @label="Your review"
      @placeholder="What did you think?"
      @maxLength={{200}}
      @showCount={{true}}
    />
  </Form>
</template>

export default ReviewForm
