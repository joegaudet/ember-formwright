import { blur, click, fillIn, find, select as selectOption, settled } from '@ember/test-helpers'

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
 *
 * Describe a form once as a class, and its fields and nested forms with decorators:
 *
 *   class SignupForm extends FormHarness {
 *     static formName = 'signup'
 *     @field(InputHarness) declare email: InputHarness
 *     @field(SelectHarness, 'plan.id') declare plan: SelectHarness
 *     @form(AddressForm) declare address: AddressForm
 *   }
 *
 * Child harnesses are created on first use and kept, so `signup.email` is one object for the
 * life of `signup`. Only the DOM lookup behind it is live, so it survives re-renders.
 */

export const selectors = {
  form: (name?: string) => (name ? `[data-test-fw-form="${name}"]` : '[data-test-fw-form]'),
  field: (path: string) => `[data-test-fw-field="${normalizePath(path)}"]`,
  option: (key: string) => `[data-test-fw-option="${CSS.escape(key)}"]`,
}

export function normalizePath(path: string): string {
  return path
    .trim()
    .replace(/\[(\w+)\]/g, '.$1')
    .replace(/^\./, '')
}

function required<T>(value: T | null | undefined, description: string): T {
  if (value === null || value === undefined) {
    throw new Error(`Formwright harness: no ${description} found`)
  }
  return value
}

/** Elements that belong to `scope` itself, not to a form nested inside it. */
function own(scope: Element, selector: string): Element[] {
  return [...scope.querySelectorAll(selector)].filter(
    el => el.closest('[data-test-fw-form]') === scope,
  )
}

type Scope = () => Element

// ---- fields ----------------------------------------------------------------------------

/**
 * A field of any control. Subclass it for your own controls: add getters that read the
 * control and async methods that act on it, and list the control names it drives.
 */
export class FieldHarness {
  /** Control names (data-test-fw-type) this harness can drive; empty means any. */
  static controls: readonly string[] = []

  readonly path: string
  private readonly scope: Scope

  constructor(scope: Scope, path: string) {
    this.scope = scope
    this.path = normalizePath(path)
  }

  /** The field's wrapper element, looked up on every read. */
  get element(): Element {
    const [el] = own(this.scope(), selectors.field(this.path))
    const element = required(el, `field "${this.path}"`)
    const { controls } = this.constructor as typeof FieldHarness
    const type = element.getAttribute('data-test-fw-type') ?? 'input'
    if (controls.length && !controls.includes(type)) {
      throw new Error(
        `Formwright harness: field "${this.path}" is a "${type}" control; this harness drives ${controls.join(', ')}`,
      )
    }
    return element
  }

  /** The element the field's <label> points at, or its first input. */
  get control(): HTMLElement {
    const element = this.element
    const id = element.querySelector('label[data-test-fw-label]')?.getAttribute('for')
    return required(
      (id && element.querySelector<HTMLElement>(`#${CSS.escape(id)}`)) ||
        element.querySelector<HTMLElement>('input, select, textarea'),
      `control in field "${this.path}"`,
    )
  }

  get type(): string {
    return this.element.getAttribute('data-test-fw-type') ?? 'input'
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
    const control = this.element.querySelector<HTMLInputElement>('input, select, textarea, button')
    return Boolean(control?.disabled) || this.element.hasAttribute('data-disabled')
  }

  /** The inline value shown before editing (`@inline` forms). */
  get displayText(): string | undefined {
    return this.element.querySelector('[data-test-fw-display]')?.textContent?.trim()
  }

  /** Inline editing: open the control. */
  async edit(): Promise<void> {
    await click(
      required(this.element.querySelector('[data-test-fw-display]'), `display for "${this.path}"`),
    )
  }

  /** Confirm mode / inline editing: apply the pending value. */
  async commit(): Promise<void> {
    await click(
      required(this.element.querySelector('[data-test-fw-commit]'), `commit for "${this.path}"`),
    )
  }

  /** Confirm mode / inline editing: discard the pending value. */
  async cancel(): Promise<void> {
    await click(
      required(this.element.querySelector('[data-test-fw-cancel]'), `cancel for "${this.path}"`),
    )
  }

  protected option(key: string): Element {
    return required(
      this.element.querySelector(selectors.option(key)),
      `option "${key}" in "${this.path}"`,
    )
  }
}

/** Text-like inputs: input, email, password, search, tel, url, color, date, time, textarea. */
export class InputHarness extends FieldHarness {
  static override controls = [
    'input',
    'text',
    'email',
    'password',
    'search',
    'tel',
    'url',
    'color',
    'date',
    'datetime',
    'time',
    'textarea',
    'masked',
  ]

  get value(): string {
    return (this.control as HTMLInputElement).value
  }

  async fillIn(text: string): Promise<void> {
    await fillIn(this.control, text)
  }
}

/** number and range: reads as a number, or null when empty. */
export class NumberHarness extends FieldHarness {
  static override controls = ['number', 'range']

  get value(): number | null {
    const raw = (this.control as HTMLInputElement).value
    return raw === '' ? null : Number(raw)
  }

  async fillIn(text: string | number): Promise<void> {
    await fillIn(this.control, String(text))
  }
}

/** currency: types the way a user would, then leaves the field so it shows formatted. */
export class CurrencyHarness extends FieldHarness {
  static override controls = ['currency']

  /** The text shown, e.g. "€1,200.00" (no-break spaces normalized to spaces). */
  get value(): string {
    return (this.control as HTMLInputElement).value.replace(/\s/g, ' ')
  }

  async fillIn(text: string): Promise<void> {
    await fillIn(this.control, text)
    await blur(this.control)
  }
}

export class SelectHarness extends FieldHarness {
  static override controls = ['select']

  /** The selected option's key, or null for the placeholder. */
  get value(): string | null {
    return (this.control as HTMLSelectElement).value || null
  }

  get options(): string[] {
    return [...this.element.querySelectorAll('[data-test-fw-option]')].map(o =>
      o.getAttribute('data-test-fw-option')!,
    )
  }

  async select(key: string): Promise<void> {
    await selectOption(this.control, key)
  }
}

export class RadioHarness extends FieldHarness {
  static override controls = ['radio']

  get value(): string | null {
    return (
      this.element.querySelector<HTMLInputElement>('[data-test-fw-option]:checked')?.value ?? null
    )
  }

  get options(): string[] {
    return [...this.element.querySelectorAll('[data-test-fw-option]')].map(o =>
      o.getAttribute('data-test-fw-option')!,
    )
  }

  async select(key: string): Promise<void> {
    await click(this.option(key))
  }
}

export class CheckboxHarness extends FieldHarness {
  static override controls = ['checkbox']

  get value(): boolean {
    return (this.control as HTMLInputElement).checked
  }

  async check(): Promise<void> {
    if (!this.value) await click(this.control)
  }

  async uncheck(): Promise<void> {
    if (this.value) await click(this.control)
  }

  async toggle(): Promise<void> {
    await click(this.control)
  }
}

export class CheckboxGroupHarness extends FieldHarness {
  static override controls = ['checkbox-group']

  /** The keys of the checked options. */
  get value(): string[] {
    return [
      ...this.element.querySelectorAll<HTMLInputElement>('[data-test-fw-option]:checked'),
    ].map(box => box.value)
  }

  /** Makes exactly these keys checked. */
  async select(keys: string[]): Promise<void> {
    const wanted = new Set(keys)
    for (const box of this.element.querySelectorAll<HTMLInputElement>('[data-test-fw-option]')) {
      if (box.checked !== wanted.has(box.value)) await click(box)
    }
  }

  async toggle(key: string): Promise<void> {
    await click(this.option(key))
  }
}

// ---- forms -----------------------------------------------------------------------------

export type HarnessClass<T> = new (...args: any[]) => T

/**
 * A form. Use it directly (`new FormHarness('signup')`) or subclass it and declare the form's
 * fields with `@field` and nested forms with `@form`.
 */
export class FormHarness {
  /** The `@name` of the form this class describes; the constructor argument wins. */
  static formName?: string

  /** The form's `@name`. Not `name`, so a form can have a field called `name`. */
  readonly formName: string | undefined
  private readonly scope: Scope
  /** Child harnesses by path or name, then by class. */
  private readonly children = new Map<string, Map<HarnessClass<unknown>, unknown>>()

  /**
   * @param name the form's `@name`; default `static formName`, else the first form on the page
   * @param parent the form this one is nested in
   */
  constructor(name?: string, parent?: FormHarness) {
    this.formName = name ?? (this.constructor as typeof FormHarness).formName
    const description = this.formName ? `form "${this.formName}"` : 'form'
    this.scope = parent
      ? () =>
          required(
            parent.element.querySelector(selectors.form(this.formName)),
            `nested ${description}`,
          )
      : () => required(find(selectors.form(this.formName)), description)
  }

  /** The <form> (or nested <fieldset>), looked up on every read. */
  get element(): Element {
    return this.scope()
  }

  /** The harness for one field, created once per path and class. */
  field<T extends FieldHarness>(path: string, Type: HarnessClass<T>): T {
    return this.child(`field:${normalizePath(path)}`, Type, () => new Type(this.scope, path))
  }

  /** The harness for a nested form (`<f.Form @name>`), created once per name and class. */
  form<T extends FormHarness = FormHarness>(name: string, Type?: HarnessClass<T>): T {
    const Class = (Type ?? FormHarness) as HarnessClass<T>
    return this.child(`form:${name}`, Class, () => new Class(name, this))
  }

  private child<T>(key: string, Type: HarnessClass<T>, create: () => T): T {
    let byClass = this.children.get(key)
    if (!byClass) this.children.set(key, (byClass = new Map()))
    if (!byClass.has(Type)) byClass.set(Type, create())
    return byClass.get(Type) as T
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
    await click(
      required(own(this.element, '[data-test-fw-reset]')[0], '<f.Reset /> button in this form'),
    )
  }
}

// ---- decorators ------------------------------------------------------------------------

/**
 * Works with both decorator implementations in use: standard decorators
 * (`@field(InputHarness) accessor email!: InputHarness`) and the legacy ones Ember apps
 * compile with (`@field(InputHarness) declare email: InputHarness`).
 */
export interface HarnessDecorator<T> {
  <This extends FormHarness>(
    target: ClassAccessorDecoratorTarget<This, T>,
    context: ClassAccessorDecoratorContext<This, T>,
  ): ClassAccessorDecoratorResult<This, T>
  // Legacy: Babel defines the descriptor this returns; TypeScript types it as void.
  (prototype: FormHarness, key: string): void
}

function decorator<T>(get: (form: FormHarness, key: string) => T): HarnessDecorator<T> {
  return ((_target: unknown, contextOrKey: string | ClassAccessorDecoratorContext) => {
    const standard = typeof contextOrKey === 'object'
    const key = String(standard ? contextOrKey.name : contextOrKey)
    function getter(this: FormHarness) {
      return get(this, key)
    }
    return standard ? { get: getter } : { configurable: true, enumerable: true, get: getter }
  }) as HarnessDecorator<T>
}

/**
 * Declares a field. The path defaults to the property name:
 *
 *   @field(InputHarness) declare email: InputHarness
 *   @field(InputHarness, 'address.city') declare city: InputHarness
 */
export function field<T extends FieldHarness>(
  Type: HarnessClass<T>,
  path?: string,
): HarnessDecorator<T> {
  return decorator((form, key) => form.field(path ?? key, Type))
}

/**
 * Declares a nested form (`<f.Form @name="...">`). The name defaults to the property name:
 *
 *   @form(AddressForm) declare address: AddressForm
 */
export function form<T extends FormHarness>(
  Type: HarnessClass<T>,
  name?: string,
): HarnessDecorator<T> {
  return decorator((parent, key) => parent.form(name ?? key, Type))
}
