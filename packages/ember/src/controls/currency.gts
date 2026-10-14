import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import type { ControlSignature } from './signature.ts'

/**
 * A number shown as money. While focused it shows the bare number for editing; on blur it
 * shows the Intl-formatted amount. Parsing follows the locale's decimal separator.
 */
export default class Currency extends Component<ControlSignature<number | null>> {
  @tracked draft: string | null = null

  get locale() {
    return this.args.locale ?? navigator.language
  }

  get formatter() {
    return new Intl.NumberFormat(this.locale, {
      style: 'currency',
      currency: this.args.currency ?? 'USD',
    })
  }

  get decimalSeparator() {
    return (
      new Intl.NumberFormat(this.locale).formatToParts(1.1).find(p => p.type === 'decimal')
        ?.value ?? '.'
    )
  }

  get displayValue() {
    if (this.draft !== null) return this.draft
    const value = this.args.value
    return value === null || value === undefined ? '' : this.formatter.format(value)
  }

  parse(raw: string): number | null {
    const sep = this.decimalSeparator
    const cleaned = [...raw]
      .filter(c => /[\d-]/.test(c) || c === sep)
      .join('')
      .replace(sep, '.')
    if (cleaned === '' || cleaned === '-') return null
    const n = Number(cleaned)
    return Number.isNaN(n) ? null : n
  }

  onFocus = () => {
    const value = this.args.value
    this.draft =
      value === null || value === undefined
        ? ''
        : new Intl.NumberFormat(this.locale, {
            useGrouping: false,
            maximumFractionDigits: 20,
          }).format(value)
  }

  onInput = (event: Event) => {
    this.draft = (event.target as HTMLInputElement).value
    this.args.onChange(this.parse(this.draft))
  }

  onBlur = () => (this.draft = null)

  <template>
    <input
      id={{@id}}
      name={{@name}}
      class="fw-control fw-input fw-currency"
      type="text"
      inputmode="decimal"
      value={{this.displayValue}}
      placeholder={{@placeholder}}
      disabled={{@disabled}}
      readonly={{@readonly}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
      {{on "focus" this.onFocus}}
      {{on "input" this.onInput}}
      {{on "blur" this.onBlur}}
    />
  </template>
}
