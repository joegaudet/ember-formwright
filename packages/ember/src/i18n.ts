import { getOwner } from '@ember/owner'

// The msgid contract (structurally the same types; Formwright doesn't depend on `msgid`).

/** A built-in string. */
export interface Message {
  /** Stable key, `formwright.<component>.<name>`. */
  id: string
  /** English text, and the gettext msgid. Placeholders are `{name}`. */
  message: string
  /** English plural, chosen by `values.count`. */
  plural?: string
  /** gettext msgctxt. */
  context?: string
  /** A note for translators. */
  description?: string
}

export interface Translator {
  /** BCP 47 locale. Make it tracked so a locale change re-renders. */
  readonly locale: string
  /** The translated, interpolated string. */
  t(message: Message, values?: Record<string, unknown>): string
}

/** A message in English: its plural for a non-`one` `values.count`, placeholders filled in. */
export function format(message: Message, values?: Record<string, unknown>): string {
  const count = values?.['count']
  const text =
    message.plural !== undefined &&
    typeof count === 'number' &&
    new Intl.PluralRules('en').select(count) !== 'one'
      ? message.plural
      : message.message
  if (!values) return text
  return text.replace(/\{(\w+)\}/g, (placeholder, name: string) =>
    name in values ? String(values[name]) : placeholder,
  )
}

/**
 * A built-in string, through the app's `translator:main` when it registered one, else in
 * English. `context` is anything with an owner: a component, a service.
 */
export function translate(
  context: object,
  message: Message,
  values?: Record<string, unknown>,
): string {
  const translator = getOwner(context)?.lookup('translator:main') as Translator | undefined
  return translator ? translator.t(message, values) : format(message, values)
}
