import {
  click,
  fillIn,
  select as selectOption,
  settled,
  triggerKeyEvent,
  find,
} from '@ember/test-helpers'

/**
 * Harnesses drive a Formwright form the way a user would, through the normalized
 * `data-test-fw-*` selectors every Formwright form renders:
 *
 *   data-test-fw-form="<name>"      the <form> (or a nested form's <fieldset>)
 *   data-test-fw-field="<path>"     a field, by its normalized model path
 *   data-test-fw-path="<a.b.path>"  the field's path from the root form
 *   data-test-fw-type="<control>"   the field's control name
 *   data-test-fw-label | -hint | -error | -display | -commit | -cancel
 *   data-test-fw-option="<key>"     one option of a select, radio or checkbox group
 *   data-test-fw-submit | -reset | -button
 */

export const selectors = {
  form: (name?: string) => (name ? `[data-test-fw-form="${name}"]` : '[data-test-fw-form]'),
  field: (path: string) => `[data-test-fw-field="${normalize(path)}"]`,
  option: (key: string) => `[data-test-fw-option="${key}"]`,
}

function normalize(path: string) {
  return path
    .trim()
    .replace(/\[(\w+)\]/g, '.$1')
    .replace(/^\./, '')
}

/** How one control type is read and written. Register more with `registerControlHarness`. */
export interface ControlDriver {
  fillIn?(field: FieldHarness, text: string): Promise<void>
  select?(field: FieldHarness, keys: string | string[]): Promise<void>
  value(field: FieldHarness): unknown
}

function input(field: FieldHarness) {
  return field.control as HTMLInputElement | null
}

const textDriver: ControlDriver = {
  async fillIn(field, text) {
    await fillIn(field.control!, text)
  },
  value: field => input(field)?.value,
}

const numberDriver: ControlDriver = {
  ...textDriver,
  value: field => {
    const raw = input(field)?.value
    return raw === undefined || raw === '' ? null : Number(raw)
  },
}

const drivers = new Map<string, ControlDriver>([
  ['number', numberDriver],
  ['range', numberDriver],
  [
    'select',
    {
      async select(field, key) {
        await selectOption(field.control!, String(key))
      },
      value: field => (field.control as HTMLSelectElement | null)?.value || null,
    },
  ],
  [
    'radio',
    {
      async select(field, key) {
        await click(field.option(String(key)))
      },
      value: field =>
        field.element.querySelector<HTMLInputElement>('[data-test-fw-option]:checked')?.value ??
        null,
    },
  ],
  [
    'checkbox-group',
    {
      async select(field, keys) {
        const wanted = new Set(([] as string[]).concat(keys).map(String))
        for (const box of field.element.querySelectorAll<HTMLInputElement>(
          '[data-test-fw-option]',
        )) {
          if (box.checked !== wanted.has(box.value)) await click(box)
        }
      },
      value: field =>
        [...field.element.querySelectorAll<HTMLInputElement>('[data-test-fw-option]:checked')].map(
          box => box.value,
        ),
    },
  ],
  ['checkbox', { value: field => input(field)?.checked ?? false }],
])

/** Teach the harness a custom control: `registerControlHarness('stepper', { ... })`. */
export function registerControlHarness(type: string, driver: ControlDriver): void {
  drivers.set(type, driver)
}

function scopeOf(root: Element | null, description: string): Element {
  if (!root) throw new Error(`Formwright harness: no ${description} found`)
  return root
}

/** Only matches elements that belong to `scope` itself, not to a nested form inside it. */
function own(scope: Element, selector: string): Element[] {
  return [...scope.querySelectorAll(selector)].filter(
    el => el.closest('[data-test-fw-form]') === scope,
  )
}

export class FieldHarness {
  private readonly formScope: () => Element
  readonly path: string

  constructor(formScope: () => Element, path: string) {
    this.formScope = formScope
    this.path = path
  }

  get element(): Element {
    const [el] = own(this.formScope(), selectors.field(this.path))
    return scopeOf(el ?? null, `field "${this.path}"`)
  }

  get type(): string {
    return this.element.getAttribute('data-test-fw-type') ?? 'input'
  }

  /** The element the field's <label> points at (the first input of a group). */
  get control(): HTMLElement | null {
    const label = this.element.querySelector('label[data-test-fw-label]')
    const id = label?.getAttribute('for')
    return (
      (id && this.element.querySelector<HTMLElement>(`#${CSS.escape(id)}`)) ||
      this.element.querySelector<HTMLElement>('input, select, textarea')
    )
  }

  get driver(): ControlDriver {
    return drivers.get(this.type) ?? textDriver
  }

  option(key: string): Element {
    return scopeOf(
      this.element.querySelector(selectors.option(key)),
      `option "${key}" in "${this.path}"`,
    )
  }

  /** The value the control currently shows (option keys for option controls). */
  get value(): unknown {
    return this.driver.value(this)
  }

  get label(): string | undefined {
    return this.element.querySelector('[data-test-fw-label]')?.textContent?.replace('*', '').trim()
  }

  get hint(): string | undefined {
    return this.element.querySelector('[data-test-fw-hint]')?.textContent?.trim()
  }

  get errors(): string[] {
    return [...this.element.querySelectorAll('[data-test-fw-error]')].map(e =>
      e.textContent!.trim(),
    )
  }

  get isInvalid(): boolean {
    return this.element.hasAttribute('data-invalid')
  }

  get isDirty(): boolean {
    return this.element.hasAttribute('data-dirty')
  }

  get isRequired(): boolean {
    return this.element.hasAttribute('data-required')
  }

  get isDisabled(): boolean {
    const control = this.control as HTMLInputElement | null
    return Boolean(control?.disabled) || this.element.hasAttribute('data-disabled')
  }

  async fillIn(text: string): Promise<void> {
    if (!this.driver.fillIn)
      throw new Error(`Formwright harness: can't fillIn a "${this.type}" control`)
    await this.driver.fillIn(this, text)
  }

  async select(keys: string | string[]): Promise<void> {
    if (!this.driver.select)
      throw new Error(`Formwright harness: can't select on a "${this.type}" control`)
    await this.driver.select(this, keys)
  }

  async check(): Promise<void> {
    if (!input(this)?.checked) await click(this.control!)
  }

  async uncheck(): Promise<void> {
    if (input(this)?.checked) await click(this.control!)
  }

  /** Inline editing: open the control. */
  async edit(): Promise<void> {
    await click(
      scopeOf(this.element.querySelector('[data-test-fw-display]'), `display for "${this.path}"`),
    )
  }

  async commit(): Promise<void> {
    await click(
      scopeOf(this.element.querySelector('[data-test-fw-commit]'), `commit for "${this.path}"`),
    )
  }

  async cancel(): Promise<void> {
    await click(
      scopeOf(this.element.querySelector('[data-test-fw-cancel]'), `cancel for "${this.path}"`),
    )
  }

  async pressEscape(): Promise<void> {
    await triggerKeyEvent(this.control!, 'keydown', 'Escape')
  }
}

export class FormHarness {
  private readonly scope: () => Element

  constructor(scope: () => Element) {
    this.scope = scope
  }

  get element(): Element {
    return this.scope()
  }

  field(path: string): FieldHarness {
    return new FieldHarness(this.scope, path)
  }

  /** A nested form (`<f.Form @name="...">`) inside this one. */
  form(name: string): FormHarness {
    return new FormHarness(() =>
      scopeOf(this.scope().querySelector(selectors.form(name)), `nested form "${name}"`),
    )
  }

  /** Form-level errors rendered by `<f.Errors />`. */
  get errors(): string[] {
    return own(this.element, '[data-test-fw-errors] [data-test-fw-error]')
      .filter(e => !e.closest('[data-test-fw-field]'))
      .map(e => e.textContent!.trim())
  }

  get isSubmitting(): boolean {
    return this.root.hasAttribute('data-submitting')
  }

  get isDirty(): boolean {
    return this.root.hasAttribute('data-dirty')
  }

  private get root(): Element {
    return this.element.closest('form') ?? this.element
  }

  /** Clicks the form's submit button if it has one, otherwise submits the <form>. */
  async submit(): Promise<void> {
    const button = this.root.querySelector('[data-test-fw-submit]')
    if (button) {
      await click(button)
    } else {
      ;(this.root as HTMLFormElement).requestSubmit()
      await settled()
    }
  }

  async reset(): Promise<void> {
    const button = own(this.element, '[data-test-fw-reset]')[0]
    if (!button) throw new Error('Formwright harness: no <f.Reset /> button in this form')
    await click(button)
  }
}

/**
 * The form named `name` (`<Form @name="...">`), or the only/first form on the page.
 *
 *   await form('signup').field('email').fillIn('ada@example.com')
 *   await form('signup').submit()
 */
export function form(name?: string): FormHarness {
  return new FormHarness(() =>
    scopeOf(find(selectors.form(name)), name ? `form "${name}"` : 'form'),
  )
}
