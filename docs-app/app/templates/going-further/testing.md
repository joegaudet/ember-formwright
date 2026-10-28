# Testing

`@ember-formwright/test-support` drives forms the way a user does, through selectors every
Formwright form renders. Describe each form once as a harness class, then use it in any test.
Every example in this guide has a **Test** tab with the test that covers it.

```bash
npm install --save-dev @ember-formwright/test-support
```

## A form is a class

```ts
import {
  FormHarness,
  InputHarness,
  SelectHarness,
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
  @field(SelectHarness, 'plan.id') declare plan: SelectHarness // the path defaults to the property name
  @field(CheckboxHarness) declare terms: CheckboxHarness
  @form(AddressForm) declare address: AddressForm // <f.Form @name="address">
}
```

```ts
test('signing up', async function (assert) {
  await render(<template><Signup /></template>)
  const signup = new SignupForm()

  await signup.email.fillIn('ada@example.com')
  await signup.plan.select('team')
  await signup.address.city.fillIn('Lisbon')
  await signup.submit()

  assert.deepEqual(signup.terms.errors, ['Please accept the terms'])
})
```

Each child harness is created once, the first time you read it, and kept: `signup.email` is the
same object for the life of `signup`. Only the DOM lookup behind it runs on every read, so a
harness survives re-renders.

With Ember's legacy decorators, write `declare` (TypeScript) or a bare field (JavaScript). With
standard decorators, write `accessor`.

## Field harnesses

| Class                  | For                                      | Adds                                                                                                                                      |
| ---------------------- | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `FieldHarness`         | any field                                | `label`, `hint`, `errors`, `isInvalid`, `isDirty`, `isRequired`, `isDisabled`, `control`, `displayText`, `edit()`, `commit()`, `cancel()` |
| `InputHarness`         | text-like controls, `textarea`, `masked` | `fillIn(text)`, `value`                                                                                                                   |
| `NumberHarness`        | `number`, `range`                        | `fillIn(n)`, `value`                                                                                                                      |
| `CurrencyHarness`      | `currency`                               | `fillIn(text)` (then blurs), `value` (as shown)                                                                                           |
| `SelectHarness`        | `select`                                 | `select(key)`, `value`, `options`                                                                                                         |
| `RadioHarness`         | `radio`                                  | `select(key)`, `value`, `options`                                                                                                         |
| `CheckboxHarness`      | `checkbox`                               | `check()`, `uncheck()`, `toggle()`, `value`                                                                                               |
| `CheckboxGroupHarness` | `checkbox-group`                         | `select(keys)`, `toggle(key)`, `value`                                                                                                    |

A harness pointed at the wrong control fails with a message that says so.

The add-on controls ship their own harnesses, each extending `FieldHarness`:

| Harness              | From                                            | For                                                                            |
| -------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------ |
| `PowerSelectHarness` | `@ember-formwright/power-select/test-support`   | [`power-select`, `power-select-multiple`](../controls/power-select.md#testing) |
| `DatePickerHarness`  | `@ember-formwright/power-calendar/test-support` | [`date-picker`, `date-range`](../controls/date-picker.md#testing)              |
| `PhoneHarness`       | `@ember-formwright/maskito/test-support`        | [`phone`](../controls/phone.md#testing)                                        |
| `FileUploadHarness`  | `@ember-formwright/file-upload/test-support`    | [`file`, `files`](../controls/file-upload.md#testing)                          |
| `RichTextHarness`    | `@ember-formwright/tiptap/test-support`         | [`rich-text`](../controls/rich-text.md#testing)                                |

A `FormHarness` has `submit()`, `reset()`, `errors` (form-level), `status`, `isDirty` and
`isSubmitting`, and `field(path, Class)` / `form(name, Class)` for one-off lookups.

## Custom controls

Subclass `FieldHarness` with getters and actions that match how a user operates the control.
The [custom controls](../controls/custom-controls.md) page has a rating control and its
harness.

## Selectors

The harnesses use these; you can too.

| Selector                                                                  | On                                                                  |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `data-test-fw-form="<name>"`                                              | The `<form>`, or a nested form's `<fieldset>`                       |
| `data-test-fw-field="<path>"`                                             | A field by model path; `items[0].name` normalizes to `items.0.name` |
| `data-test-fw-path="<root.path>"`                                         | The same field, from the root form                                  |
| `data-test-fw-type="<control>"`                                           | The field's control name                                            |
| `data-test-fw-label`, `-hint`, `-error`, `-display`, `-commit`, `-cancel` | Parts of a field                                                    |
| `data-test-fw-option="<key>"`                                             | An option of a select, radio or checkbox group                      |
| `data-test-fw-submit`, `-reset`, `-button`                                | Buttons                                                             |

<div class="callout">

**Coming from ember-foxy-forms**

`data-test-form-for`, `data-test-field-for` and the `--field-for__…` testing classes are
replaced by the selectors above.

</div>
