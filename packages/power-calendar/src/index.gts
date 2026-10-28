import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import BasicDropdown from 'ember-basic-dropdown/components/basic-dropdown'
import type { Dropdown } from 'ember-basic-dropdown/types'
import PowerCalendar from 'ember-power-calendar/components/power-calendar'
import PowerCalendarRange from 'ember-power-calendar/components/power-calendar-range'
import type {
  NormalizeCalendarValue,
  NormalizeRangeActionValue,
  PowerCalendarDay,
} from 'ember-power-calendar/utils'
import { registerControl, type ControlSignature } from '@ember-formwright/ember'
import { ensureDateLibrary } from './date-library.ts'
import {
  formatDate,
  formatDateRange,
  toDate,
  toDateRange,
  toIsoDate,
  type DateRangeValue,
  type DateValue,
} from './dates.ts'

export {
  formatDate,
  formatDateRange,
  toDate,
  toIsoDate,
  type DateRangeValue,
  type DateValue,
  type FormatOptions,
} from './dates.ts'
export { nativeDateLibrary } from './date-library.ts'

export interface DatePickerControlSignature {
  /** A wrapper around the trigger and its dropdown, carrying the control's hooks and attributes. */
  Element: HTMLDivElement
  Args: ControlSignature['Args'] & {
    /** Store `Date`s rather than ISO `YYYY-MM-DD` strings. */
    storeDate?: boolean
    /** `Intl.DateTimeFormat` options for the trigger's text. Default `{ dateStyle: 'medium' }`. */
    dateFormat?: Intl.DateTimeFormatOptions
    /** Days that can't be chosen: dates, or English weekday names ('Sat', 'Sun'). */
    disabledDates?: Array<Date | string>
    /** First day of the week, 0 (Sunday) to 6. Default: the locale's. */
    startOfWeek?: number
    /** Render the dropdown in place rather than in the wormhole. Forced in a callout. */
    renderInPlace?: boolean
    /** date-range: the shortest and longest range, in days. Default: no limits. */
    minRange?: number
    maxRange?: number
  }
}

/**
 * A Formwright control: a button showing the date, opening an ember-power-calendar in an
 * ember-basic-dropdown. It stores an ISO `YYYY-MM-DD` string (a `Date` with `@storeDate`),
 * and reads either.
 */
export class DatePickerControl extends Component<DatePickerControlSignature> {
  /** The month shown, once the user has moved away from the value's. */
  @tracked center: Date | null = null
  /** date-range: the start chosen before the end, kept here until the range is complete. */
  @tracked pending: { start: Date | null; end: Date | null } | null = null

  get isRange(): boolean {
    return false
  }

  get selectedDate(): Date | undefined {
    return toDate(this.args.value)
  }

  get selectedRange(): { start: Date | null; end: Date | null } {
    if (this.pending) return this.pending
    const { start, end } = toDateRange(this.args.value)
    return { start: start ?? null, end: end ?? null }
  }

  get currentCenter(): Date {
    if (this.center) return this.center
    const selected = this.isRange ? this.selectedRange.start : this.selectedDate
    return selected ?? new Date()
  }

  get text(): string {
    const options = { locale: this.args.locale, format: this.args.dateFormat }
    return this.isRange
      ? formatDateRange(this.args.value, options)
      : formatDate(this.args.value, options)
  }

  /**
   * The trigger's name: the label, then what it shows (the value, else the placeholder), so
   * both are read out. Without a label, the button's text names it.
   */
  get ariaLabel(): string | undefined {
    const label = this.args.label
    if (!label) return undefined
    const shown = this.text || this.args.placeholder
    return shown ? `${label}: ${shown}` : label
  }

  get disabled(): boolean {
    // Like the built-in select, readonly disables it: there is nothing to read-only open.
    return Boolean(this.args.disabled || this.args.readonly)
  }

  /** Inside a callout the dropdown must stay inside the popover (the top layer). */
  get renderInPlace(): boolean | undefined {
    return this.args.callout ? true : this.args.renderInPlace
  }

  get minDate(): Date | undefined {
    return toDate(this.args.min)
  }

  get maxDate(): Date | undefined {
    return toDate(this.args.max)
  }

  get startOfWeek(): string | undefined {
    return this.args.startOfWeek === undefined ? undefined : String(this.args.startOfWeek)
  }

  get minRange(): number {
    return this.args.minRange ?? 0
  }

  store(date: Date | null | undefined): DateValue | null {
    if (!date) return null
    return this.args.storeDate ? toDate(date)! : toIsoDate(date)
  }

  onCenterChange = (value: NormalizeCalendarValue): void => {
    this.center = value.date ?? null
  }

  onSelect = (dropdown: Dropdown, day: PowerCalendarDay): void => {
    this.args.onChange(this.store(day.date))
    this.done(dropdown)
  }

  onSelectRange = (dropdown: Dropdown, value: NormalizeRangeActionValue): void => {
    const { start = null, end = null } = value.date
    if (start && end) {
      const range: DateRangeValue = { start: this.store(start), end: this.store(end) }
      this.args.onChange(range)
      this.done(dropdown)
    } else {
      this.pending = { start, end }
    }
  }

  /** Closes the dropdown and puts focus back on the trigger. */
  done(dropdown: Dropdown): void {
    dropdown.actions.close()
    dropdown.actions.getTriggerElement()?.focus()
  }

  onClose = (): void => {
    this.center = null
    this.pending = null
  }

  /**
   * While the dropdown is open, Enter and Escape belong to it: Enter chooses the focused day,
   * Escape closes the dropdown. Neither reaches the field, which would commit or cancel.
   */
  onKeydown = (dropdown: Dropdown, event: KeyboardEvent): void => {
    if (!dropdown.isOpen) return
    if (event.key === 'Escape') {
      event.preventDefault()
      this.done(dropdown)
    }
    if (event.key === 'Escape' || event.key === 'Enter') event.stopPropagation()
  }

  /** Makes our own `<button>` the dropdown's trigger, for positioning and outside clicks. */
  registerTrigger = modifier((element: HTMLElement, [dropdown]: [Dropdown]) => {
    dropdown.actions.registerTriggerElement(element)
  })

  <template>
    <div
      class="fw-date-picker-control{{if this.isRange ' fw-date-picker-control--range'}}"
      data-test-fw-control={{@type}}
      data-fw-name={{@name}}
      ...attributes
    >
      <BasicDropdown
        @renderInPlace={{this.renderInPlace}}
        @disabled={{this.disabled}}
        @onClose={{this.onClose}}
        as |dd|
      >
        <button
          type="button"
          id={{@id}}
          class="fw-control fw-date-picker"
          data-ebd-id="{{dd.uniqueId}}-trigger"
          aria-label={{this.ariaLabel}}
          aria-haspopup="dialog"
          aria-expanded={{if dd.isOpen "true" "false"}}
          aria-controls="ember-basic-dropdown-content-{{dd.uniqueId}}"
          aria-describedby={{@describedBy}}
          aria-invalid={{if @invalid "true"}}
          disabled={{this.disabled}}
          {{this.registerTrigger dd}}
          {{on "click" dd.actions.toggle}}
          {{on "keydown" (fn this.onKeydown dd)}}
        >
          {{#if this.text}}
            <span class="fw-date-picker-value" data-test-fw-date-value>{{this.text}}</span>
          {{else}}
            <span class="fw-date-picker-placeholder">{{@placeholder}}</span>
          {{/if}}
          <svg
            class="fw-date-picker-icon"
            viewBox="0 0 24 24"
            width="18"
            height="18"
            aria-hidden="true"
          >
            <rect x="3" y="5" width="18" height="16" rx="2" />
            <path d="M3 10h18M8 3v4M16 3v4" />
          </svg>
        </button>
        <dd.Content
          class="fw-date-picker-dropdown"
          data-test-fw-calendar
          {{on "keydown" (fn this.onKeydown dd)}}
        >
          {{#if this.isRange}}
            <PowerCalendarRange
              class="fw-calendar fw-calendar--range"
              @selected={{this.selectedRange}}
              @center={{this.currentCenter}}
              @locale={{@locale}}
              @minRange={{this.minRange}}
              @maxRange={{@maxRange}}
              @onCenterChange={{this.onCenterChange}}
              @onSelect={{fn this.onSelectRange dd}}
              as |calendar|
            >
              <calendar.Nav />
              <calendar.Days
                @minDate={{this.minDate}}
                @maxDate={{this.maxDate}}
                @disabledDates={{@disabledDates}}
                @startOfWeek={{this.startOfWeek}}
                @weekdayFormat="min"
                @autofocus={{true}}
              />
            </PowerCalendarRange>
          {{else}}
            <PowerCalendar
              class="fw-calendar"
              @selected={{this.selectedDate}}
              @center={{this.currentCenter}}
              @locale={{@locale}}
              @onCenterChange={{this.onCenterChange}}
              @onSelect={{fn this.onSelect dd}}
              as |calendar|
            >
              <calendar.Nav />
              <calendar.Days
                @minDate={{this.minDate}}
                @maxDate={{this.maxDate}}
                @disabledDates={{@disabledDates}}
                @startOfWeek={{this.startOfWeek}}
                @weekdayFormat="min"
                @autofocus={{true}}
              />
            </PowerCalendar>
          {{/if}}
        </dd.Content>
      </BasicDropdown>
    </div>
  </template>
}

/** The same control, choosing a range: stores `{ start, end }` once both ends are chosen. */
export class DateRangeControl extends DatePickerControl {
  override get isRange(): boolean {
    return true
  }
}

/**
 * Makes `@control="date-picker"` and `@control="date-range"` available to every form, and
 * gives ember-power-calendar a date library built on `Date` and `Intl` unless the app
 * registered one. Call once, e.g. in app.ts.
 */
export function registerPowerCalendarControls({
  single = 'date-picker',
  range = 'date-range',
}: { single?: string; range?: string } = {}): void {
  ensureDateLibrary()
  registerControl(single, DatePickerControl)
  registerControl(range, DateRangeControl)
}
