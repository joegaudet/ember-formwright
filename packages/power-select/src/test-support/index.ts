import { waitUntil } from '@ember/test-helpers'
import { FieldHarness } from '@ember-formwright/test-support'
import {
  clearSelected,
  getDropdownItems,
  removeMultipleOption,
  selectChoose,
  selectSearch,
} from 'ember-power-select/test-support'

/**
 * Drives a `power-select` or `power-select-multiple` field with power-select's own test
 * helpers:
 *
 *   class OwnerForm extends FormHarness {
 *     @field(PowerSelectHarness) declare owner: PowerSelectHarness
 *   }
 *
 *   await form.owner.search('ada')
 *   await form.owner.select('Ada Lovelace')
 *   assert.deepEqual(form.owner.selected, ['Ada Lovelace'])
 */
export class PowerSelectHarness extends FieldHarness {
  static override controls = ['power-select', 'power-select-multiple']

  /** The trigger: the focusable element the field's label points at. */
  get trigger(): HTMLElement {
    return this.control
  }

  /** A selector for this field alone, for helpers that take one. */
  private get fieldSelector(): string {
    const path = this.element.getAttribute('data-test-fw-path') ?? this.path
    return `[data-test-fw-path="${CSS.escape(path)}"]`
  }

  get isMultiple(): boolean {
    return this.type === 'power-select-multiple' || this.trigger.matches('[aria-multiselectable]')
  }

  /** The text of each selected option, as the trigger shows it. */
  get selected(): string[] {
    const items = this.isMultiple
      ? this.trigger.querySelectorAll('.ember-power-select-multiple-option')
      : this.trigger.querySelectorAll('.ember-power-select-selected-item')
    return [...items].map(item =>
      (item.querySelector('.fw-power-select-option') ?? item)
        .textContent!.replace(/\s+/g, ' ')
        .trim(),
    )
  }

  /** Whether the dropdown is open. */
  get isOpen(): boolean {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  /** Opens the dropdown if needed and clicks the option whose text contains `label`. */
  async select(label: string): Promise<void> {
    await selectChoose(this.trigger, label)
  }

  /** The open dropdown, which power-select renders outside the field (or in place). */
  get dropdown(): Element | null {
    const id = this.trigger.getAttribute('data-ebd-id')?.replace(/-trigger$/, '')
    return id ? document.getElementById(`ember-basic-dropdown-content-${id}`) : null
  }

  /** Types into the search field, then waits for `@search` to return its options. */
  async search(text: string): Promise<void> {
    await selectSearch(this.trigger, text)
    await waitUntil(
      () => !this.dropdown?.querySelector('.ember-power-select-option--loading-message'),
      { timeoutMessage: `Formwright harness: search in "${this.path}" never finished loading` },
    )
  }

  /** The text of each option in the open dropdown (opening it first). */
  async options(): Promise<string[]> {
    return (await getDropdownItems(this.trigger)).map(text => text?.replace(/\s+/g, ' ') ?? '')
  }

  /** Clears the selection: the ✕ of `@allowClear`, or every chip of a multiple select. */
  async clear(): Promise<void> {
    if (!this.isMultiple) return clearSelected(this.fieldSelector)
    for (const label of this.selected) await removeMultipleOption(this.fieldSelector, label)
  }

  /** Multiple select: removes one chosen option by its text. */
  async remove(label: string): Promise<void> {
    await removeMultipleOption(this.fieldSelector, label)
  }
}
