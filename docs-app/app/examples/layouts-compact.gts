import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerLayouts } from '@ember-formwright/layouts'

registerLayouts()

const STATUSES = ['Open', 'Closed', 'Any']

export class Filters {
  @tracked query = ''
  @tracked status = 'Open'
}

export const createModel = () => new Filters()

const FilterBar: TOC<{ Args: { model: Filters } }> = <template>
  <Form @model={{@model}} @name="filters" @layout="compact" as |f|>
    <f.Field @for="query" @control="search" @label="Search" @placeholder="Title or id" />
    <f.Field @for="status" @control="select" @label="Status" @options={{STATUSES}} />
  </Form>
</template>

export default FilterBar
