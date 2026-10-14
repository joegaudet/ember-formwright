import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import { Form, type ControlSignature } from '@formwright/ember'

interface Range {
  min: number
  max: number
}

/**
 * One field can edit a whole object: this control binds to `{ min, max }`.
 * (ember-foxy-forms called these composite fields.)
 */
export class PriceRange extends Component<ControlSignature<Range>> {
  get range(): Range {
    return this.args.value ?? { min: 0, max: 0 }
  }

  setMin = (event: Event) =>
    this.args.onChange({ ...this.range, min: Number((event.target as HTMLInputElement).value) })
  setMax = (event: Event) =>
    this.args.onChange({ ...this.range, max: Number((event.target as HTMLInputElement).value) })

  <template>
    <div class="price-range" data-test-fw-control={{@type}}>
      <input
        id={{@id}}
        class="fw-control fw-input"
        type="number"
        aria-label="Minimum"
        value={{this.range.min}}
        disabled={{@disabled}}
        data-test-range-min
        {{on "input" this.setMin}}
      />
      <span aria-hidden="true">to</span>
      <input
        class="fw-control fw-input"
        type="number"
        aria-label="Maximum"
        value={{this.range.max}}
        disabled={{@disabled}}
        data-test-range-max
        {{on "input" this.setMax}}
      />
    </div>

    <style>
      .price-range {
        display: flex;
        align-items: center;
        gap: 0.6rem;
      }
      .price-range .fw-input {
        width: 7rem;
        flex: none;
      }
    </style>
  </template>
}

export class Search {
  @tracked price: Range = { min: 100, max: 400 }
}

export const createModel = () => new Search()

const SearchForm: TOC<{ Args: { model: Search } }> = <template>
  <Form @model={{@model}} @name="search" as |f|>
    <f.Field @for="price" @control={{PriceRange}} @label="Price per night" @hint="In euros." />
  </Form>
</template>

export default SearchForm
