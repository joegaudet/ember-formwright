# @ember-formwright/test-support

Harness classes for testing Formwright forms the way a user uses them.

```bash
npm install --save-dev @ember-formwright/test-support
```

## Describe a form once

A form is a `FormHarness` subclass. Decorators declare its fields, each with the harness class
for its control, and its nested forms:

```ts
import {
  FormHarness,
  InputHarness,
  SelectHarness,
  CheckboxGroupHarness,
  CheckboxHarness,
  field,
  form,
} from '@ember-formwright/test-support'

export class AddressForm extends FormHarness {
  @field(InputHarness) declare city: InputHarness
}

export class SignupForm extends FormHarness {
  static formName = 'signup' // <Form @name="signup">; omit for the first form on the page

  @field(InputHarness) declare email: InputHarness
  @field(SelectHarness, 'plan.id') declare plan: SelectHarness // path defaults to the property
  @field(CheckboxGroupHarness) declare notify: CheckboxGroupHarness
  @field(CheckboxHarness) declare terms: CheckboxHarness
  @form(AddressForm) declare address: AddressForm // <f.Form @name="address">
}
```

Then use it:

```ts
const signup = new SignupForm()

await signup.email.fillIn('ada@example.com')
await signup.plan.select('team') // by option key
await signup.notify.select(['email', 'sms']) // the full selection
await signup.terms.check()
await signup.address.city.fillIn('Lisbon')
await signup.submit()

signup.email.value // what the control shows
signup.email.errors // ['That email looks off']
signup.email.isInvalid // also: isDirty, isRequired, isDisabled, label, hint
signup.errors // form-level errors from <f.Errors />
```

Each child harness is created once, the first time you read it, and kept: `signup.email` is
the same object for the life of `signup`. Only the DOM lookup behind it is live, so a harness
survives re-renders. Without a subclass, `new FormHarness('signup').field('email',
InputHarness)` gives you the same cached harness.

With Ember's legacy decorators, write `declare` (TypeScript) or a bare field (JavaScript):
`@field(InputHarness) email;`. With standard decorators, write `accessor`.

## Field harnesses

| Class                  | Controls                                                                                | Adds                                                                                                                                      |
| ---------------------- | --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `FieldHarness`         | any                                                                                     | `label`, `hint`, `errors`, `isInvalid`, `isDirty`, `isRequired`, `isDisabled`, `control`, `edit()`, `commit()`, `cancel()`, `displayText` |
| `InputHarness`         | input, email, password, search, tel, url, color, date, datetime, time, textarea, masked | `fillIn(text)`, `value`                                                                                                                   |
| `NumberHarness`        | number, range                                                                           | `fillIn(n)`, `value: number \| null`                                                                                                      |
| `CurrencyHarness`      | currency                                                                                | `fillIn(text)` (then blurs), `value` (the formatted text)                                                                                 |
| `SelectHarness`        | select                                                                                  | `select(key)`, `value`, `options`                                                                                                         |
| `RadioHarness`         | radio                                                                                   | `select(key)`, `value`, `options`                                                                                                         |
| `CheckboxHarness`      | checkbox                                                                                | `check()`, `uncheck()`, `toggle()`, `value: boolean`                                                                                      |
| `CheckboxGroupHarness` | checkbox-group                                                                          | `select(keys)`, `toggle(key)`, `value: string[]`                                                                                          |

A harness pointed at the wrong control fails with a message saying so.

## Custom controls

Subclass `FieldHarness`, and optionally list the control names it drives:

```ts
class StepperHarness extends FieldHarness {
  static controls = ['stepper'] // optional; @control={{Component}} fields are "custom"

  get value(): number {
    return Number(this.element.querySelector('output')!.textContent)
  }

  async increment(): Promise<void> {
    await click(this.element.querySelector('button')!)
  }
}

class OrderForm extends FormHarness {
  @field(StepperHarness) declare seats: StepperHarness
}
```

## Selectors

Every Formwright form renders these; the harnesses use them, and so can you:

| Selector                                                                  | On                                                                   |
| ------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `data-test-fw-form="<name>"`                                              | The `<form>`, or a nested form's `<fieldset>`                        |
| `data-test-fw-field="<path>"`                                             | A field, by model path; `items[0].name` normalizes to `items.0.name` |
| `data-test-fw-path="<form.path>"`                                         | The field's path from the root form                                  |
| `data-test-fw-type="<control>"`                                           | The control name the field uses                                      |
| `data-test-fw-label`, `-hint`, `-error`, `-display`, `-commit`, `-cancel` | Parts of a field                                                     |
| `data-test-fw-option="<key>"`                                             | An option of a select, radio or checkbox group                       |
| `data-test-fw-submit`, `-reset`, `-button`                                | Form buttons                                                         |
