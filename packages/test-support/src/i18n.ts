import { getContext, type TestContext } from '@ember/test-helpers'

// The msgid contract's types, declared structurally: Formwright doesn't depend on `msgid`.
export interface Message {
  id: string
  message: string
  plural?: string
  context?: string
  description?: string
}

export interface Translator {
  readonly locale: string
  t(message: Message, values?: Record<string, unknown>): string
}

/**
 * Registers `translator` as the app's `translator:main` for the current test, the way an app
 * does in an instance initializer. Call it once, before `render`; each test starts without one.
 */
export function registerTranslator(translator: Translator): void {
  const { owner } = getContext() as TestContext
  owner.register('translator:main', translator, { instantiate: false })
}

const ACCENTS: Record<string, string> = {
  a: 'à',
  b: 'ƀ',
  c: 'ć',
  e: 'ē',
  f: 'ƒ',
  h: 'ĥ',
  i: 'ĩ',
  l: 'ĺ',
  m: 'ɱ',
  n: 'ñ',
  o: 'ō',
  s: 'ś',
  t: 'ţ',
  u: 'ũ',
  A: 'À',
  C: 'Ć',
  E: 'Ē',
  I: 'Ĩ',
  O: 'Ō',
  S: 'Ś',
  U: 'Ũ',
}

const accent = (text: string) => text.replace(/[a-zA-Z]/g, c => ACCENTS[c] ?? c)

/**
 * A pseudo-locale: `⟦` + accented English + `⟧`. Register it and any built-in string still
 * plain English skipped the translator. Placeholders are filled in, not accented.
 */
export const pseudoTranslator: Translator = {
  locale: 'en-XA',
  t(message, values = {}) {
    const count = values['count']
    const one = typeof count !== 'number' || new Intl.PluralRules('en').select(count) === 'one'
    const text = message.plural !== undefined && !one ? message.plural : message.message
    const filled = text
      .split(/(\{\w+\})/)
      .map(part => {
        const name = /^\{(\w+)\}$/.exec(part)?.[1]
        if (name === undefined) return accent(part)
        return name in values ? String(values[name]) : part
      })
      .join('')
    return `⟦${filled}⟧`
  },
}
