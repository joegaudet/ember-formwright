import { settled } from '@ember/test-helpers'
import { FieldHarness } from '@ember-formwright/test-support'

/**
 * Drives a `phone` field (`@ember-formwright/maskito/phone`):
 *
 *   class ContactForm extends FormHarness {
 *     @field(PhoneHarness) declare phone: PhoneHarness
 *   }
 *
 *   await form.phone.fillIn('2125550123')
 *   assert.strictEqual(form.phone.value, '+1 212 555-0123')
 */
export class PhoneHarness extends FieldHarness {
  static override controls = ['phone']

  get input(): HTMLInputElement {
    return this.control as HTMLInputElement
  }

  /** The number as shown, masked. */
  get value(): string {
    return this.input.value
  }

  /**
   * Replaces the text, as a paste or autofill would, and lets the mask shape it. Maskito
   * handles the change, so the field stores what the mask kept.
   */
  async fillIn(text: string): Promise<void> {
    const input = this.input
    input.focus()
    input.value = text
    input.dispatchEvent(new InputEvent('input', { bubbles: true, inputType: 'insertText' }))
    await settled()
  }

  /** Empties the input. */
  async clear(): Promise<void> {
    await this.fillIn('')
  }
}
