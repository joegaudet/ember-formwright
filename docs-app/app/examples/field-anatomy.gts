import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'

export class Listing {
  @tracked title = ''
  @tracked price: number | null = 1250
}

export const createModel = () => new Listing()

const asPrice = (value: unknown) =>
  value == null ? '' : `$${Number(value).toLocaleString('en-US')}`

const ListingForm: TOC<{ Args: { model: Listing } }> = <template>
  <Form @model={{@model}} @name="listing" as |f|>
    <f.Field
      @for="title"
      @label="Title"
      @hint="Shown in search results."
      @placeholder="e.g. Sunny two-bedroom near the park"
      @required={{true}}
    />
    <f.Field @for="price" @control="number" @label="Monthly rent" @min={{0}} @step={{50}} />
  </Form>

  <h4>The same values, shown with <code>@format</code> in inline mode</h4>
  <Form @model={{@model}} @name="listing-inline" @inline={{true}} as |f|>
    <f.Field @for="title" @label="Title" @placeholder="No title yet" />
    <f.Field @for="price" @control="number" @label="Monthly rent" @format={{asPrice}} />
  </Form>
</template>

export default ListingForm
