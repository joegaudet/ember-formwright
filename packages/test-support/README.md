# @formwright/test-support

Harnesses for testing Formwright forms the way a user uses them.

```bash
npm install --save-dev @formwright/test-support
```

```ts
import { form } from '@formwright/test-support'

const signup = form('signup') // <Form @name="signup">; form() is the first form on the page

await signup.field('email').fillIn('ada@example.com')
await signup.field('plan').select('team') // select and radio: by option key
await signup.field('notify').select(['email', 'sms']) // checkbox-group: the full selection
await signup.field('terms').check()
await signup.form('address').field('city').fillIn('Lisbon') // nested <f.Form @name="address">
await signup.submit()

signup.field('email').value // what the control shows (option keys for option controls)
signup.field('email').errors // ['That email looks off']
signup.field('email').isInvalid // also: isDirty, isRequired, isDisabled, label, hint
signup.errors // form-level errors from <f.Errors />
```

Inline editing: `field.edit()`, then `fillIn`, then `field.commit()` or `field.cancel()`.

## Selectors

Every Formwright form renders these, so you can also use them directly:

| Selector                                                                  | On                                                                   |
| ------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `data-test-fw-form="<name>"`                                              | The `<form>`, or a nested form's `<fieldset>`                        |
| `data-test-fw-field="<path>"`                                             | A field, by model path; `items[0].name` normalizes to `items.0.name` |
| `data-test-fw-path="<form.path>"`                                         | The field's path from the root form                                  |
| `data-test-fw-type="<control>"`                                           | The control name the field uses                                      |
| `data-test-fw-label`, `-hint`, `-error`, `-display`, `-commit`, `-cancel` | Parts of a field                                                     |
| `data-test-fw-option="<key>"`                                             | An option of a select, radio or checkbox group                       |
| `data-test-fw-submit`, `-reset`, `-button`                                | Form buttons                                                         |

## Custom controls

The harness picks a driver from `data-test-fw-type`. Teach it yours:

```ts
import { registerControlHarness } from '@formwright/test-support'

registerControlHarness('stepper', {
  value: field => Number(field.element.querySelector('output')!.textContent),
  fillIn: async (field, text) => {
    /* ... */
  },
})
```

Controls passed as a component (`@control={{MyControl}}`) have the type `custom`.
