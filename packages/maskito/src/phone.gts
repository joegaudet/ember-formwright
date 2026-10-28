import Component from '@glimmer/component'
import { cached } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import { Maskito, maskitoTransform, type MaskitoOptions } from '@maskito/core'
import { maskitoPhone } from '@maskito/phone'
import minMetadata from 'libphonenumber-js/min/metadata'
import {
  getCountryCallingCode,
  isValidPhoneNumber,
  parsePhoneNumberFromString,
  type CountryCode,
  type MetadataJson,
} from 'libphonenumber-js/core'
import { registerControl, type ControlSignature } from '@ember-formwright/ember'

export type { CountryCode, MetadataJson }

export interface PhoneSignature {
  Element: HTMLInputElement
  Args: ControlSignature<string | null>['Args'] & {
    /** The country whose numbers are typed (ISO 3166 code). Default `US`. */
    country?: CountryCode
    /**
     * Only numbers of `@country`, with its calling code fixed in front (default). With
     * `false`, any country's number can be typed, starting with `+`.
     */
    strict?: boolean
    /** Strict mode: show the national format, without the calling code, e.g. `(212) 555-0123`. */
    national?: boolean
    /** libphonenumber-js metadata. Default its `min` metadata. */
    metadata?: MetadataJson
  }
}

/**
 * A phone number input, masked as it is typed by `@maskito/phone`. It stores the number in
 * E.164 form (`+12125550123`), or `null` when empty, and shows it formatted:
 *
 *   <f.Field @for="phone" @control="phone" @label="Phone" as |field|>
 *     <field.Control @country="GB" />
 *   </f.Field>
 */
export default class PhoneControl extends Component<PhoneSignature> {
  /** What was last typed; shown while it still stands for the stored value. */
  private typed: string | undefined

  get country(): CountryCode {
    return this.args.country ?? 'US'
  }

  get strict(): boolean {
    return this.args.strict ?? true
  }

  get national(): boolean {
    return Boolean(this.args.national) && this.strict
  }

  get metadata(): MetadataJson {
    return this.args.metadata ?? (minMetadata as unknown as MetadataJson)
  }

  get callingCode(): string {
    return getCountryCallingCode(this.country, this.metadata)
  }

  /** The Maskito options, rebuilt only when what they depend on changes. */
  @cached
  get options(): MaskitoOptions {
    return maskitoPhone({
      countryIsoCode: this.country,
      metadata: this.metadata,
      strict: this.strict,
      format: this.national ? 'NATIONAL' : 'INTERNATIONAL',
    })
  }

  /** The E.164 form of what is shown: `+` and its digits, or null when nothing is typed. */
  toE164(text: string): string | null {
    const digits = text.replace(/\D/g, '')
    if (!digits) return null
    if (this.national) return `+${this.callingCode}${digits}`
    // Strict mode keeps the calling code in front; on its own it is not a number yet.
    if (this.strict && digits === this.callingCode) return null
    return `+${digits}`
  }

  /** A stored number, as the mask shows it. */
  format(value: string): string {
    let digits = value.replace(/[^\d+]/g, '')
    if (this.national) {
      const prefix = `+${this.callingCode}`
      digits = digits.startsWith(prefix) ? digits.slice(prefix.length) : digits.replace('+', '')
    }
    return maskitoTransform(digits, this.options)
  }

  get shown(): string {
    const value = this.args.value ?? null
    if (this.typed !== undefined && this.toE164(this.typed) === value) return this.typed
    return value ? this.format(value) : ''
  }

  mask = modifier((element: HTMLInputElement, [options]: [MaskitoOptions]) => {
    const maskito = new Maskito(element, options)
    return () => maskito.destroy()
  })

  onInput = (event: Event) => {
    const text = (event.target as HTMLInputElement).value
    const value = this.toE164(text)
    this.typed = text
    if (value !== (this.args.value ?? null)) this.args.onChange(value)
  }

  <template>
    <input
      id={{@id}}
      name={{@name}}
      class="fw-control fw-input fw-phone"
      type="tel"
      autocomplete="tel"
      inputmode="tel"
      value={{this.shown}}
      placeholder={{@placeholder}}
      disabled={{@disabled}}
      readonly={{@readonly}}
      required={{@required}}
      aria-invalid={{if @invalid "true"}}
      aria-describedby={{@describedBy}}
      data-test-fw-control={{@type}}
      ...attributes
      {{this.mask this.options}}
      {{on "input" this.onInput}}
    />
  </template>
}

/**
 * Whether a stored number is a valid phone number, for a validator. A number without a `+`
 * is read as `country`'s. Uses libphonenumber-js's `min` metadata unless given other metadata.
 *
 *   z.string().refine(v => isValidPhone(v), 'That number looks off')
 */
export function isValidPhone(
  value: string | null | undefined,
  country?: CountryCode,
  metadata: MetadataJson = minMetadata as unknown as MetadataJson,
): boolean {
  if (!value) return false
  return isValidPhoneNumber(value, { defaultCountry: country }, metadata)
}

/**
 * A stored number in international format (`+1 212 555 0123`), for a field's `@format`.
 * Anything that doesn't parse is shown as it is.
 */
export function formatPhone(
  value: string | null | undefined,
  metadata: MetadataJson = minMetadata as unknown as MetadataJson,
): string {
  if (!value) return ''
  return parsePhoneNumberFromString(value, metadata)?.formatInternational() ?? value
}

/** Makes `@control="phone"` available to every form. Call once, e.g. in app.ts. */
export function registerPhoneControl(name = 'phone'): void {
  registerControl(name, PhoneControl)
}

export { PhoneControl }
