/** A stored date: an ISO `YYYY-MM-DD` string, or a `Date` with `@storeDate`. */
export type DateValue = string | Date

/** A stored range. Either end may be empty. */
export interface DateRangeValue<V extends DateValue = DateValue> {
  start: V | null
  end: V | null
}

const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})/

/**
 * The calendar day a value stands for, as a local `Date` at midnight: from a `Date`, or from
 * a string starting with `YYYY-MM-DD` (the time, if any, is ignored). Anything else is
 * `undefined`.
 */
export function toDate(value: unknown): Date | undefined {
  if (value instanceof Date) {
    return isNaN(+value)
      ? undefined
      : new Date(value.getFullYear(), value.getMonth(), value.getDate())
  }
  if (typeof value === 'string') {
    const match = ISO_DATE.exec(value)
    if (match) return new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
  }
  return undefined
}

/** A local `Date` as `YYYY-MM-DD`. */
export function toIsoDate(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

/** Both ends of a stored range, as dates. */
export function toDateRange(value: unknown): { start: Date | undefined; end: Date | undefined } {
  const range = (value ?? {}) as Partial<DateRangeValue>
  return { start: toDate(range.start), end: toDate(range.end) }
}

export interface FormatOptions {
  /** A BCP 47 locale; default the browser's. */
  locale?: string
  /** `Intl.DateTimeFormat` options; default `{ dateStyle: 'medium' }`. */
  format?: Intl.DateTimeFormatOptions
}

const DEFAULT_FORMAT: Intl.DateTimeFormatOptions = { dateStyle: 'medium' }

function formatter({ locale, format }: FormatOptions): Intl.DateTimeFormat {
  return new Intl.DateTimeFormat(locale, format ?? DEFAULT_FORMAT)
}

/**
 * A stored date as text, e.g. "Mar 4, 2026"; empty for no date. Pass it to a field's
 * `@format` for inline mode.
 */
export function formatDate(value: unknown, options: FormatOptions = {}): string {
  const date = toDate(value)
  return date ? formatter(options).format(date) : ''
}

/**
 * A stored range as text, e.g. "Mar 4 – 9, 2026"; one end with a dash when the other is
 * empty, and empty for no range.
 */
export function formatDateRange(value: unknown, options: FormatOptions = {}): string {
  const { start, end } = toDateRange(value)
  const f = formatter(options)
  if (start && end) return f.formatRange(start, end)
  if (start) return `${f.format(start)} –`
  if (end) return `– ${f.format(end)}`
  return ''
}
