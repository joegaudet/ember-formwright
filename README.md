# Formwright

Declarative, accessible forms for Ember. One `<Form>`, one `<f.Field>`: labels, ids, errors,
`aria-invalid`, dirty state, reset and nested saves are handled. Bring any validator (zod,
valibot, any [Standard Schema](https://standardschema.dev)) and any data layer (WarpDrive,
ember-data, ember-changeset, plain objects), and test it with harnesses that read the way your users do.

Site and live demo: **https://joegaudet.com/ember-formwright/**

Guide, with a live example of every feature: **https://joegaudet.com/ember-formwright/guide/**

Formwright is the successor to `ember-foxy-forms`. Coming from there? See [MIGRATION.md](MIGRATION.md).

## Install

```bash
npm install @ember-formwright/ember
npm install --save-dev @ember-formwright/test-support
```

Works with Ember 6.12 LTS and 7.x, in Vite (Embroider) apps and classic ember-cli apps.

## Use

```gts
import { Form } from '@ember-formwright/ember'
import '@ember-formwright/ember/theme.css' // optional: a theme driven by --fw-* custom properties
import { z } from 'zod'

const userSchema = z.object({ email: z.string().email('That email looks off') })
// A nested form validates its own model, so its errors land on its own fields.
const addressSchema = z.object({ city: z.string().min(1, 'City is required') })

<template>
  <Form @model={{@user}} @name="signup" @validator={{userSchema}} @onSubmit={{@save}} as |f|>
    <f.Field @for="email" @control="email" @label="Email" @hint="We never share it" />
    <f.Field @for="plan" @control="select" @label="Plan" @options={{@plans}} />

    <f.Form @model={{@user.address}} @name="address" @validator={{addressSchema}} as |a|>
      <a.Field @for="city" @label="City" />
    </f.Form>

    <f.Errors />
    <f.Submit>Sign up</f.Submit>
    <f.Reset />
  </Form>
</template>
```

### `<Form>`

| Argument                                                      |                                                                                   |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `@model`                                                      | The object being edited. POJOs and `@tracked` classes work as-is.                 |
| `@name`                                                       | Names the form for selectors and harnesses. Default `"form"`.                     |
| `@validator`                                                  | A Standard Schema (zod, valibot, ArkType, ...) or `(model) => ErrorMap`.          |
| `@adapter`                                                    | How to read, write, save and roll back the model. See [Adapters](#adapters).      |
| `@onSubmit`                                                   | Saves the model. Default: the adapter's save (`model.save()` if it exists).       |
| `@willSubmit`, `@didSubmit`, `@failedSubmit`, `@didNotSubmit` | Submit lifecycle. `willSubmit` may return `false` to cancel.                      |
| `@willReset`, `@didReset`                                     | Reset lifecycle.                                                                  |
| `@onChange`                                                   | `(path, value, model)` after each committed change.                               |
| `@disabled`, `@readonly`                                      | Flow down to every field.                                                         |
| `@inline`, `@callout`                                         | Inline editing: show values, edit on click; `@callout` edits in a native popover. |
| `@requireConfirm`                                             | Changes wait for ✔ (or Enter), ✘ (or Esc) discards them.                          |
| `@autoSubmit`                                                 | Submit after every committed change.                                              |
| `@resetOnDestroy`                                             | Roll back unsaved changes on teardown. Default `true`.                            |

It yields `Field`, `Form` (nested, renders a `<fieldset>`; pass `@legend`), `Submit`, `Reset`,
`Button`, `Errors` (form-level errors) and `state` (`status`, `isDirty`, `isSubmitting`,
`isValid`, `errors`, `submit()`, `reset()`, `validate()`). `status` is the form's state:
`clean`, `dirty`, `invalid` or `submitting`, also set as `data-status` on the `<form>`.

Validation runs on submit. After a failed submit it re-runs on every change, so errors clear as
they are fixed, and focus moves to the first invalid control. Nested forms validate and save
with their root: the parent first, then dirty (or new) children, breadth-first.

### `<f.Field>`

| Argument                                              |                                                                                                                                                                             |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@for`                                                | The model path: `"email"`, `"address.city"`, `"items[0].name"`.                                                                                                             |
| `@label`, `@hint`, `@placeholder`, `@required`        |                                                                                                                                                                             |
| `@control`                                            | A built-in or registered control name (default `"input"`), or a component.                                                                                                  |
| `@options`, `@optionKey`, `@optionLabel`, `@storeKey` | For `select`, `radio` and `checkbox-group`. Options can be primitives or objects; the key defaults to `id`, then `value`. `@storeKey` stores the key instead of the option. |
| `@min`, `@max`, `@step`                               | Bounds; for `checkbox-group`, `@max` caps the selection.                                                                                                                    |
| `@disabled`, `@readonly`, `@requireConfirm`           | Override the form.                                                                                                                                                          |
| `@format`                                             | Formats the value shown in inline mode.                                                                                                                                     |

Built-in controls: `input`, `email`, `password`, `search`, `tel`, `url`, `number`, `range`,
`color`, `date`, `datetime`, `time`, `textarea`, `select`, `radio`, `checkbox`,
`checkbox-group` and `currency` (`Intl.NumberFormat`; pass `@currency` and `@locale`).

With a block, the field yields its `Control` already wired, for control-specific arguments or
your own layout; the label, hint and errors still render around it:

```gts
<f.Field @for="bio" @control="textarea" @label="Bio" as |field|>
  <field.Control @maxLength={{280}} @showCount={{true}} />
</f.Field>
```

### Custom controls

Any component with `ControlSignature` works: put `@id` on the focusable element and call
`@onChange(value)`.

```gts
import { registerControl, type ControlSignature } from '@ember-formwright/ember'

class Stepper extends Component<ControlSignature<number>> {
  inc = () => this.args.onChange((this.args.value ?? 0) + 1)
  <template>
    <button id={{@id}} type="button" {{on "click" this.inc}}>{{@value}}</button>
  </template>
}

registerControl('stepper', Stepper) // then @control="stepper", or pass @control={{Stepper}}
```

## Adapters

The core edits any object through a `ModelAdapter` (`get`, `set`, and optionally `save`,
`rollback`, `errorsFor`, `needsSave`). Set one per form with `@adapter`, or for every form with
`setDefaultAdapter()`. Without `rollback`, reset restores the values the form's fields had when
they rendered or last saved.

| Package                                                       |                                                                                                                       |
| ------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| [`@ember-formwright/warp-drive`](packages/warp-drive)         | WarpDrive / ember-data records: save, rollback, server errors, nested new records.                                    |
| [`@ember-formwright/changeset`](packages/changeset)           | ember-changeset: edits buffered until a valid submit, validations, rollback.                                          |
| [`@ember-formwright/real-enums`](packages/real-enums)         | [real-enums](https://joegaudet.com/real-enums/) classes as options.                                                   |
| [`@ember-formwright/maskito`](packages/maskito)               | A `masked` control powered by Maskito, and a `phone` control (`@ember-formwright/maskito/phone`) storing E.164.       |
| [`@ember-formwright/power-select`](packages/power-select)     | Searchable, async and multiple selects powered by ember-power-select.                                                 |
| [`@ember-formwright/power-calendar`](packages/power-calendar) | `date-picker` and `date-range` controls powered by ember-power-calendar.                                              |
| [`@ember-formwright/file-upload`](packages/file-upload)       | `file` and `files` controls: a drop zone, file list and optional uploads with progress, powered by ember-file-upload. |
| [`@ember-formwright/tiptap`](packages/tiptap)                 | A `rich-text` control with a toolbar, storing HTML or JSON, powered by Tiptap.                                        |
| [`@ember-formwright/layouts`](packages/layouts)               | Field layouts (horizontal, compact, checkbox-after) and an `Actions` bar.                                             |
| [`@ember-formwright/test-support`](packages/test-support)     | Form harnesses for tests.                                                                                             |

## Testing

Describe each form once as a harness class. Decorators declare its fields (with the harness
for their control) and nested forms; each is created once, on first use.

```ts
import {
  FormHarness,
  InputHarness,
  SelectHarness,
  field,
  form,
} from '@ember-formwright/test-support'

class AddressForm extends FormHarness {
  @field(InputHarness) declare city: InputHarness
}

class SignupForm extends FormHarness {
  static formName = 'signup'

  @field(InputHarness) declare email: InputHarness
  @field(SelectHarness) declare plan: SelectHarness
  @form(AddressForm) declare address: AddressForm
}

const signup = new SignupForm()
await signup.email.fillIn('ada@example.com')
await signup.plan.select('team')
await signup.address.city.fillIn('Lisbon')
await signup.submit()
assert.deepEqual(signup.email.errors, [])
```

Every form renders normalized `data-test-fw-*` selectors that the harnesses use; see the
[test-support README](packages/test-support/README.md).

## Repository

| Path                      |                                                        |
| ------------------------- | ------------------------------------------------------ |
| `packages/*`              | The published packages                                 |
| `test-app/`               | The test suite (Vite + ember-qunit), and the live demo |
| `examples/ember-classic/` | A classic ember-cli app using the addon, run in CI     |
| `docs/site/`              | The hand-written site                                  |

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE.md)
