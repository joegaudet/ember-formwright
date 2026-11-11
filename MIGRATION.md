# Migrating

## From Formwright 1.x to 2.0

2.0 types each field's control against its path. Nothing changes at runtime; `ember-tsc` reports
what used to slip through.

- **A control must fit its path.** The path must hold what the control stores. A field
  without `@control` is a text input, so a number, boolean or list path needs one
  (`@control="number"`).
- **Mind `null`.** `number` and `currency` store `null` when emptied, and `select`
  when its blank option is picked. Type those paths to allow it: `seats: number | null`.
- **Options are typed.** `@options` must hold what the path does, unless `@storeKey` stores
  their keys.
- **A field takes only its control's args.** `@currency` on a text field is an error. Args a
  field doesn't pass on (`@mask`, your control's own) go through the yielded `Control`, which is
  now typed by the control.
- **Declare registered controls.** `registerControl('rating', StarRating)` still works, but
  `@control="rating"` is only typed once the name is declared:

  ```ts
  declare module '@ember-formwright/ember' {
    interface FormwrightControls {
      rating: ControlSignature<number>
    }
  }
  ```

  A control whose value follows the path (a select, a combobox) goes in
  `FormwrightChoiceControls<T>` instead. The add-on packages declare their default names.

- **`ControlSignature` is split.** `ControlSignature<Value, Extra, Element>` is the wiring every
  control gets (`ControlWiring`) plus its own args. A custom control that read `@options`,
  `@min` or `@currency` declares them in `Extra`; `OptionArgs`, `RangeArgs` and `LengthArgs`
  cover the common ones. `@value` is typed `Value | null | undefined`.
- **A control chosen at runtime** (`@control={{def.type}}`, typed `string`) can't be checked.
  Type it as the names that fit the path (`ControlsFor<PathValue<Model, 'plan'>>`), or as
  `ControlName` on a loose model (`Record<string, unknown>`).
- **Some add-on controls follow the path.** What `date-picker`, `rich-text` and `file` store
  depends on `@storeDate`, `@output` and `@upload`, which go through the yielded control, so
  their types follow the path: keep the two in step.
- **Loose models give `unknown`.** `PathValue` of a model typed `object` was `never`; it is now
  `unknown`, like `any` and `Record<string, unknown>` models, and takes any control.

## From ember-foxy-forms

Formwright is ember-foxy-forms rebuilt for modern Ember: a v2 addon, written in TypeScript
with `.gts` components, imported in strict-mode templates. The ideas carry over (a form owns a
model, fields bind to paths, nested forms save together) but most names changed, and some
features moved into your app.

## Install

```bash
npm uninstall ember-foxy-forms
npm install @ember-formwright/ember
```

Requires Ember 6.12 or newer. Templates must be `.gjs`/`.gts` (or import the components into a
strict-mode template); there are no globally resolved `<FormFor>`/`<FieldFor>` components.

```gts
import { Form } from '@ember-formwright/ember'
```

## Components

| ember-foxy-forms                                                | Formwright                                                                      |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `<FormFor @model=… as \|f\|>` / `<Form @for=…>`                 | `<Form @model=… as \|f\|>`                                                      |
| `<f.field @for="name" @using="input" />` / `f.fieldFor`         | `<f.Field @for="name" @control="input" />`                                      |
| `@using="…"`                                                    | `@control="…"` (a name or a component)                                          |
| `@values=` (array or `"id:label,…"` string)                     | `@options=` (array only)                                                        |
| `@params` / array `@for` with `@withMapping` (composite fields) | Removed. Bind a custom control to the parent object, or use one field per path. |
| `<f.submit />`, `<f.reset />`, `<f.button />`                   | `<f.Submit />`, `<f.Reset />`, `<f.Button @onClick=… />`                        |
| `<f.destroy />` with `@confirmsDestroy`                         | Removed. Use `<f.Button @onClick={{this.delete}}>` and your own confirm.        |
| `<f.errors />`                                                  | `<f.Errors />`                                                                  |
| `@parentForm={{f.self}}` on a nested `<FormFor>`                | `<f.Form @model=…>` (renders a `<fieldset>`)                                    |
| `f.self`                                                        | `f.state`                                                                       |
| `LabelFor`, custom label/error/info components                  | The field renders them; restyle with CSS or use the field's block form.         |

## Arguments

| ember-foxy-forms                                  | Formwright                                                                                                    |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `@inlineEditing`                                  | `@inline`                                                                                                     |
| `@hasControlCallout` (ember-attacher popover)     | `@callout` (native `popover`, CSS anchor positioning)                                                         |
| `@requireConfirm`                                 | `@requireConfirm` (same)                                                                                      |
| `@autoSubmit`                                     | `@autoSubmit` (same)                                                                                          |
| `@disabled`, `@readonly`                          | Same                                                                                                          |
| `@infoText`                                       | `@hint`                                                                                                       |
| `@formatValue`                                    | `@format`                                                                                                     |
| `@displayValueComponent`                          | Use the field's block form, or `@format`.                                                                     |
| `@labelKey` / `@idKey` on selects                 | `@optionLabel` / `@optionKey`                                                                                 |
| `@storeAsPrimitive`                               | `@storeKey`                                                                                                   |
| `@selectionMax` (checkbox select)                 | `@max`                                                                                                        |
| `@using="checkbox-select"`                        | `@control="checkbox-group"`                                                                                   |
| `@using="currency"` (ember-inputmask)             | `@control="currency"` (`Intl.NumberFormat`; `@currency`, `@locale`), or `@ember-formwright/maskito` for masks |
| `@using="multiple-input"`                         | Removed (see composite fields above).                                                                         |
| `@enforceRequiredFields`                          | Removed. Validate with `@validator`; `@required` marks a field.                                               |
| `@resetOnDestroy`, `@resetIfDirtyOnly`            | `@resetOnDestroy` (resets only when dirty)                                                                    |
| `@allowSubmitQueue`                               | Removed: a submit while submitting is ignored.                                                                |
| `@scrollToFirstVisibleError`                      | Always on, as focus: the first invalid control is focused.                                                    |
| `@useEmberDataDirtyTracking`                      | Use `@ember-formwright/warp-drive`.                                                                           |
| `@valueTooltip`, `@editText` (inline editing)     | Removed. Put the text in your own markup, or in `@hint`.                                                      |
| `showRequiredIndicator`, `requiredText` (config)  | `@required` always shows `*` (`.fw-required`); hide or restyle it with CSS.                                   |
| `@tagName` (form), `@fieldTagName`                | Removed. A form is a `<form>` (a nested one a `<fieldset>`), and a field a `<div>`.                           |
| `@infoText` component (`customInfoTextComponent`) | `@hint`, or the field's block form.                                                                           |

## Hooks

| ember-foxy-forms                                                   | Formwright                                                  |
| ------------------------------------------------------------------ | ----------------------------------------------------------- |
| `@willSubmit` (validation)                                         | `@validator`                                                |
| `@confirmSubmit`                                                   | `@willSubmit` (return `false` to cancel)                    |
| `@onSubmit`, `@didSubmit`, `@failedSubmit`, `@didNotSubmit`        | Same names                                                  |
| `@childDidSubmit`, `@childFailedSubmit`                            | Pass `@didSubmit`/`@failedSubmit` to the nested `<f.Form>`. |
| `@willReset` + `@confirmReset`                                     | `@willReset`                                                |
| `@onReset`, `@didReset`                                            | `@didReset` (rollback is the adapter's job)                 |
| `@onUpdateValues`                                                  | `@onChange(path, value, model)`                             |
| `@onMarkedDirty`, `@onMarkedClean`                                 | Read `f.state.isDirty`.                                     |
| `@didCommitValue`, `@didResetValue` on fields                      | `@onChange` on the form.                                    |
| `@runValidations`, `model.validate()` (ember-cp-validations style) | `@validator`: any Standard Schema or `(model) => ErrorMap`. |

## The `form-for` service and config

The `formFor` service and `ENV.APP['ember-foxy-forms']` config are gone.

- **Classes** (`formClasses`, `fieldClasses`, BEM and grid-template options): style the stable
  `.fw-*` classes and `data-invalid` / `data-dirty` / `data-disabled` / `data-required`
  attributes, and set `--fw-*` custom properties if you use the theme.
- **Notifications** (`notifySuccess`, `notifyError` and the `*Message` arguments): call your
  notification service from `@didSubmit` / `@failedSubmit`.
- **Navigation guard** (`preventsNavigationByDefault`): read `f.state.isDirty` and abort the
  transition in your route or router service:

  ```ts
  this.router.on('routeWillChange', transition => {
    if (this.form?.isDirty && !confirm('Discard your changes?')) transition.abort()
  })
  ```

## Tests

`data-test-form-for`, `data-test-field-for` and the `--field-for__…` testing classes are
replaced by normalized `data-test-fw-*` selectors and the harness classes in
`@ember-formwright/test-support`:

```ts
// before
await fillIn('[data-test-field-for="user_email"] input', 'a@b.co')

// after: describe the form once…
class UserForm extends FormHarness {
  static formName = 'user'
  @field(InputHarness) declare email: InputHarness
}

// …then use it
await new UserForm().email.fillIn('a@b.co')
```
