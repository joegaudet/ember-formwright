import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import { registerPowerCalendarControls, formatDate } from '@ember-formwright/power-calendar'

registerPowerCalendarControls()

/** Weekdays only. */
const WEEKEND = ['Sat', 'Sun']

export class Release {
  /** An ember-data `@attr('date')` holds a Date: store one with @storeDate. */
  @tracked shipsOn: Date | null = new Date(2026, 10, 18)
}

export const createModel = () => new Release()

/** Inline mode shows the value as text; formatDate reads a Date or an ISO string. */
const longDate = (value: Date | null) =>
  formatDate(value, { locale: 'en-US', format: { dateStyle: 'full' } })

const ReleaseForm: TOC<{ Args: { model: Release } }> = <template>
  <Form @model={{@model}} @name="release" @inline={{true}} @callout={{true}} as |f|>
    <f.Field
      @for="shipsOn"
      @control="date-picker"
      @label="Ships on"
      @hint="A weekday in November or December"
      @format={{longDate}}
      @min="2026-11-02"
      @max="2026-12-18"
      @locale="en-US"
      as |field|
    >
      <field.Control @storeDate={{true}} @disabledDates={{WEEKEND}} />
    </f.Field>
  </Form>
</template>

export default ReleaseForm
