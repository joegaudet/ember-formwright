import { click, triggerKeyEvent } from '@ember/test-helpers'
import { FieldHarness } from '@ember-formwright/test-support'

/**
 * Drives a `date-picker` or `date-range` field the way a user would: open the calendar,
 * page to the month, click the day.
 *
 *   class TripForm extends FormHarness {
 *     @field(DatePickerHarness) declare departure: DatePickerHarness
 *     @field(DatePickerHarness) declare stay: DatePickerHarness
 *   }
 *
 *   await trip.departure.select('2026-03-04')
 *   await trip.stay.selectRange('2026-03-04', '2026-03-09')
 *   assert.strictEqual(trip.departure.text, 'Mar 4, 2026')
 */
export class DatePickerHarness extends FieldHarness {
  static override controls = ['date-picker', 'date-range']

  /** The button the field's label points at. */
  get trigger(): HTMLButtonElement {
    return this.control as HTMLButtonElement
  }

  /** The value as the trigger shows it, e.g. "Mar 4, 2026"; empty when there is none. */
  get text(): string {
    return (
      this.trigger
        .querySelector('[data-test-fw-date-value]')
        ?.textContent?.replace(/\s+/g, ' ')
        .trim() ?? ''
    )
  }

  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** The open calendar, which renders outside the field (or in place, in a callout). */
  get calendar(): HTMLElement | null {
    const id = this.trigger.getAttribute('aria-controls')
    return id ? document.getElementById(id) : null
  }

  /** The month shown, e.g. "March 2026". */
  get month(): string {
    return this.requireCalendar()
      .querySelector('.ember-power-calendar-nav-title')!
      .textContent!.trim()
  }

  async open(): Promise<void> {
    if (!this.isOpen) await click(this.trigger)
  }

  /** Closes the calendar with Escape, as a keyboard user would. */
  async close(): Promise<void> {
    if (this.isOpen) await triggerKeyEvent(this.trigger, 'keydown', 'Escape')
  }

  async nextMonth(): Promise<void> {
    await click(this.navButton('next'))
  }

  async previousMonth(): Promise<void> {
    await click(this.navButton('previous'))
  }

  /** Opens the calendar and pages to the month of `date` (`YYYY-MM-DD`). */
  async goTo(date: string): Promise<void> {
    await this.open()
    for (let i = 0; i < 1200; i++) {
      const shown = this.shownMonth()
      const wanted = date.slice(0, 7)
      if (shown === wanted) return
      await (wanted < shown ? this.previousMonth() : this.nextMonth())
    }
    throw new Error(`Formwright harness: "${this.path}" never showed the month of ${date}`)
  }

  /** The day button for `date` (`YYYY-MM-DD`) in the month shown, if it is there. */
  day(date: string): HTMLButtonElement | null {
    return this.requireCalendar().querySelector<HTMLButtonElement>(
      `.ember-power-calendar-day--current-month[data-date="${date}"]`,
    )
  }

  /** Whether `date` can't be chosen (before `@min`, after `@max`, or in `@disabledDates`). */
  async isDayDisabled(date: string): Promise<boolean> {
    await this.goTo(date)
    return Boolean(this.day(date)?.disabled)
  }

  /** Opens the calendar, pages to `date` (`YYYY-MM-DD`) and clicks it. */
  async select(date: string): Promise<void> {
    await this.goTo(date)
    const day = this.day(date)
    if (!day) throw new Error(`Formwright harness: no day ${date} in "${this.path}"`)
    if (day.disabled)
      throw new Error(`Formwright harness: day ${date} in "${this.path}" is disabled`)
    await click(day)
  }

  /** date-range: chooses both ends. */
  async selectRange(start: string, end: string): Promise<void> {
    await this.select(start)
    await this.select(end)
  }

  private shownMonth(): string {
    const day = this.requireCalendar().querySelector('.ember-power-calendar-day--current-month')
    return day!.getAttribute('data-date')!.slice(0, 7)
  }

  private navButton(which: 'next' | 'previous'): Element {
    const button = this.requireCalendar().querySelector(
      `.ember-power-calendar-nav-control--${which}`,
    )
    if (!button) throw new Error(`Formwright harness: no ${which}-month button in "${this.path}"`)
    return button
  }

  private requireCalendar(): HTMLElement {
    const calendar = this.isOpen ? this.calendar : null
    if (!calendar) throw new Error(`Formwright harness: the calendar of "${this.path}" is not open`)
    return calendar
  }
}
