import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
import {
  registerPowerCalendarControls,
  type DateRangeValue,
} from '@ember-formwright/power-calendar'

// Once, at boot (e.g. app/app.ts): @control="date-picker" and "date-range".
registerPowerCalendarControls()

export class Booking {
  /** An ISO date string: what a date-picker stores. */
  @tracked checkIn: string | null = '2026-11-12'
  /** A date-range stores { start, end } once both ends are chosen. */
  @tracked stay: DateRangeValue<string> | null = { start: '2026-11-12', end: '2026-11-16' }
}

export const createModel = () => new Booking()

const BookingForm: TOC<{ Args: { model: Booking } }> = <template>
  <Form @model={{@model}} @name="booking" as |f|>
    <f.Field
      @for="checkIn"
      @control="date-picker"
      @label="Check-in"
      @placeholder="Pick a day"
      @locale="en-US"
    />
    <f.Field
      @for="stay"
      @control="date-range"
      @label="Stay"
      @hint="Click the first night, then the last"
      @placeholder="Check-in – check-out"
      @locale="en-US"
    />
  </Form>
</template>

export default BookingForm
