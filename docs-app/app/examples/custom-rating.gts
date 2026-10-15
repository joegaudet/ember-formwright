import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import type { TOC } from '@ember/component/template-only'
import { Form, registerControl, type ControlSignature } from '@ember-formwright/ember'

/**
 * A control is any component with ControlSignature: render @value, call @onChange.
 * Put @id on the first focusable element so the field's label (here, legend) points at it.
 */
export class StarRating extends Component<ControlSignature<number>> {
  stars = [1, 2, 3, 4, 5]

  idFor = (star: number) => (star === 1 ? this.args.id : `${this.args.id}-${star}`)
  isLit = (star: number) => star <= (this.args.value ?? 0)
  rate = (star: number) => this.args.onChange(star)

  <template>
    <div class="star-rating" data-test-fw-control={{@type}}>
      {{#each this.stars as |star|}}
        <input
          type="radio"
          class="star-input"
          name={{@id}}
          id={{this.idFor star}}
          value={{star}}
          checked={{if (eqStar star @value) true false}}
          disabled={{@disabled}}
          aria-invalid={{if @invalid "true"}}
          data-test-fw-option={{star}}
          {{on "change" (fn this.rate star)}}
        />
        <label for={{this.idFor star}} class="star {{if (this.isLit star) 'is-lit'}}">
          <span class="visually-hidden">{{star}} star{{if (eqStar star 1) "" "s"}}</span>★
        </label>
      {{/each}}
    </div>

    <style>
      .star-rating {
        display: inline-flex;
        gap: 0.15rem;
      }
      .star-input {
        position: absolute;
        opacity: 0;
        width: 1px;
        height: 1px;
      }
      .star {
        font-size: 1.75rem;
        line-height: 1;
        color: var(--fw-border);
        cursor: pointer;
      }
      .star.is-lit {
        color: #f59e0b;
      }
      .star-input:focus-visible + .star {
        outline: 2px solid var(--fw-border-focus);
        border-radius: 4px;
      }
      .star-input:disabled + .star {
        cursor: not-allowed;
        opacity: 0.5;
      }
      .visually-hidden {
        position: absolute;
        width: 1px;
        height: 1px;
        overflow: hidden;
        clip-path: inset(50%);
      }
    </style>
  </template>
}

function eqStar(a: number, b: number | undefined) {
  return a === b
}

// A group control: its field renders a <fieldset> with the label as its <legend>.
registerControl('rating', StarRating, { group: true })

export class Feedback {
  @tracked quality = 4
  @tracked support = 0
}

export const createModel = () => new Feedback()

const FeedbackForm: TOC<{ Args: { model: Feedback } }> = <template>
  <Form @model={{@model}} @name="feedback" as |f|>
    <f.Field @for="quality" @control="rating" @label="Product quality" />
    <f.Field @for="support" @control={{StarRating}} @label="Support (passed as a component)" />
  </Form>
</template>

export default FeedbackForm
