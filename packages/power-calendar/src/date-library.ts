import { getDefaultLocale, registerDateLibrary, type DateLibrary } from 'ember-power-calendar/utils'

/*
 * ember-power-calendar delegates date math to a registered "date library" (its moment and
 * luxon packages are two). This one uses the platform's `Date` and `Intl`, so the controls
 * need no date package. An app that registered its own library keeps it.
 */

const DAY_MS = 86_400_000

/** The locale set by `withLocale` while power-calendar renders; the default otherwise. */
let currentLocale: string | null = null

function locale(): string {
  return currentLocale ?? defaultLocale()
}

function defaultLocale(): string {
  return new Intl.DateTimeFormat().resolvedOptions().locale
}

function unitOf(unit: string): string {
  return unit.replace(/s$/, '')
}

function add(date: Date, quantity: number, unit: string): Date {
  const d = new Date(date)
  switch (unitOf(unit)) {
    case 'year':
      d.setFullYear(d.getFullYear() + quantity)
      break
    case 'month': {
      // Clamp to the target month's last day, as moment and luxon do (Jan 31 + 1 month = Feb 28).
      const day = d.getDate()
      d.setDate(1)
      d.setMonth(d.getMonth() + quantity)
      d.setDate(Math.min(day, new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()))
      break
    }
    case 'week':
      d.setDate(d.getDate() + 7 * quantity)
      break
    case 'day':
      d.setDate(d.getDate() + quantity)
      break
    case 'hour':
      d.setHours(d.getHours() + quantity)
      break
    case 'minute':
      d.setMinutes(d.getMinutes() + quantity)
      break
    default:
      d.setTime(d.getTime() + quantity)
  }
  return d
}

function startOf(date: Date, unit: string): Date {
  switch (unitOf(unit)) {
    case 'year':
      return new Date(date.getFullYear(), 0, 1)
    case 'month':
      return new Date(date.getFullYear(), date.getMonth(), 1)
    case 'week':
      return startOfWeek(startOf(date, 'day'), localeStartOfWeek(locale()))
    default:
      return new Date(date.getFullYear(), date.getMonth(), date.getDate())
  }
}

function endOf(date: Date, unit: string): Date {
  switch (unitOf(unit)) {
    case 'year':
      return new Date(date.getFullYear(), 11, 31, 23, 59, 59, 999)
    case 'month':
      return new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999)
    case 'week':
      return endOf(endOfWeek(date, localeStartOfWeek(locale())), 'day')
    default:
      return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999)
  }
}

/** 1 (Monday) to 7 (Sunday). */
function isoWeekday(date: Date): number {
  return date.getDay() || 7
}

function isSame(a: Date, b: Date, unit: string): boolean {
  // power-calendar also compares days with `@disabledDates` entries such as 'Sat'.
  if (!(a instanceof Date) || !(b instanceof Date)) return false
  const u = unitOf(unit)
  if (u === 'week') return +startOf(a, 'week') === +startOf(b, 'week')
  if (a.getFullYear() !== b.getFullYear()) return false
  if (u === 'year') return true
  if (a.getMonth() !== b.getMonth()) return false
  if (u === 'month') return true
  return a.getDate() === b.getDate()
}

/** Weekday names from Sunday, as power-calendar expects. */
function weekdays(format: 'long' | 'short' | 'narrow'): string[] {
  const formatter = new Intl.DateTimeFormat(locale(), { weekday: format })
  // 2023-01-01 was a Sunday.
  return Array.from({ length: 7 }, (_, i) => formatter.format(new Date(2023, 0, 1 + i)))
}

const TOKENS = /YYYY|MMMM|MMM|MM|M|DD|D|dddd|ddd/g

function formatDate(date: Date, format: string, locale_: string | null = null): string {
  const loc = locale_ ?? locale()
  // The nav title: let Intl order the month and year for the locale.
  if (format === 'MMMM YYYY') {
    return new Intl.DateTimeFormat(loc, { month: 'long', year: 'numeric' }).format(date)
  }
  const pad = (n: number) => String(n).padStart(2, '0')
  return format.replace(TOKENS, token => {
    switch (token) {
      case 'YYYY':
        return String(date.getFullYear())
      case 'MMMM':
        return new Intl.DateTimeFormat(loc, { month: 'long' }).format(date)
      case 'MMM':
        return new Intl.DateTimeFormat(loc, { month: 'short' }).format(date)
      case 'MM':
        return pad(date.getMonth() + 1)
      case 'M':
        return String(date.getMonth() + 1)
      case 'DD':
        return pad(date.getDate())
      case 'D':
        return String(date.getDate())
      case 'dddd':
        return new Intl.DateTimeFormat(loc, { weekday: 'long' }).format(date)
      default:
        // `ddd` is compared with English names (`disabledDates` takes 'Sat', 'Sun', ...).
        return new Intl.DateTimeFormat('en-US', { weekday: 'short' }).format(date)
    }
  })
}

const DURATION_UNITS: Record<string, number> = {
  w: 7 * DAY_MS,
  d: DAY_MS,
  h: 3_600_000,
  m: 60_000,
  s: 1000,
}

function normalizeDuration(value: unknown): number | null | undefined {
  if (value === null) return null
  if (typeof value === 'number') return value
  if (typeof value === 'string') {
    const [, quantity = '', unit = 'd'] = value.match(/(\d+)\s*([a-z]*)/i) ?? []
    return parseInt(quantity, 10) * (DURATION_UNITS[unit.charAt(0)] ?? DAY_MS)
  }
  return undefined
}

/** 0 (Sunday) to 6, from `Intl.Locale`'s week info where the browser has it. */
function localeStartOfWeek(name: string): number {
  try {
    const loc = new Intl.Locale(name) as Intl.Locale & {
      getWeekInfo?: () => { firstDay: number }
      weekInfo?: { firstDay: number }
    }
    const info = loc.getWeekInfo?.() ?? loc.weekInfo
    if (info) return info.firstDay % 7
  } catch {
    // An unknown locale: fall through.
  }
  return 0
}

function startOfWeek(day: Date, start: number): Date {
  const d = new Date(day)
  while (d.getDay() !== start) d.setDate(d.getDate() - 1)
  return d
}

function endOfWeek(day: Date, start: number): Date {
  const d = new Date(day)
  while (d.getDay() !== (start + 6) % 7) d.setDate(d.getDate() + 1)
  return d
}

export const nativeDateLibrary: DateLibrary = {
  add,
  formatDate,
  startOf,
  endOf,
  weekday: date => date.getDay(),
  isoWeekday,
  getWeekdaysShort: () => weekdays('short'),
  getWeekdaysMin: () => weekdays('narrow'),
  getWeekdays: () => weekdays('long'),
  isAfter: (a, b) => +a > +b,
  isBefore: (a, b) => +a < +b,
  isSame,
  isBetween: (date, start, end) => +start <= +date && +date <= +end,
  diff: (a, b) => +a - +b,
  normalizeDate: date => (date instanceof Date ? date : undefined),
  normalizeRangeActionValue: value => ({ date: value.date }),
  normalizeMultipleActionValue: value => ({ date: value.date }),
  normalizeCalendarDay: day => day,
  withLocale: (name, fn) => {
    const previous = currentLocale
    currentLocale = name || previous
    try {
      return fn()
    } finally {
      currentLocale = previous
    }
  },
  normalizeCalendarValue: value => ({ date: value?.date }),
  normalizeDuration,
  getDefaultLocale: defaultLocale,
  localeStartOfWeek,
  startOfWeek,
  endOfWeek,
}

/** Registers the native date library, unless the app registered one already. */
export function ensureDateLibrary(): void {
  try {
    getDefaultLocale()
  } catch {
    registerDateLibrary(nativeDateLibrary)
  }
}
