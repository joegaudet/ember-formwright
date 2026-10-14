# Migrating from ember-foxy-forms

Formwright is ember-foxy-forms rebuilt for modern Ember: a v2 addon, written in TypeScript
with `.gts` components, imported in strict-mode templates. The ideas carry over (a form owns a
model, fields bind to paths, nested forms save together) but most names changed, and some
features moved into your app.

## Install

```bash
npm uninstall ember-foxy-forms
npm install @formwright/ember
```

Requires Ember 6.12 or newer. Templates must be `.gjs`/`.gts` (or import the components into a
strict-mode template); there are no globally resolved `<FormFor>`/`<FieldFor>` components.

```gts
import { Form } from '@formwright/ember'
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

| ember-foxy-forms                              | Formwright                                                                                              |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `@inlineEditing`                              | `@inline`                                                                                               |
| `@hasControlCallout` (ember-attacher popover) | `@callout` (native `popover`, CSS anchor positioning)                                                   |
| `@requireConfirm`                             | `@requireConfirm` (same)                                                                                |
| `@autoSubmit`                                 | `@autoSubmit` (same)                                                                                    |
| `@disabled`, `@readonly`                      | Same                                                                                                    |
| `@infoText`                                   | `@hint`                                                                                                 |
| `@formatValue`                                | `@format`                                                                                               |
| `@displayValueComponent`                      | Use the field's block form, or `@format`.                                                               |
| `@labelKey` / `@idKey` on selects             | `@optionLabel` / `@optionKey`                                                                           |
| `@storeAsPrimitive`                           | `@storeKey`                                                                                             |
| `@selectionMax` (checkbox select)             | `@max`                                                                                                  |
| `@using="checkbox-select"`                    | `@control="checkbox-group"`                                                                             |
| `@using="currency"` (ember-inputmask)         | `@control="currency"` (`Intl.NumberFormat`; `@currency`, `@locale`), or `@formwright/maskito` for masks |
| `@using="multiple-input"`                     | Removed (see composite fields above).                                                                   |
| `@enforceRequiredFields`                      | Removed. Validate with `@validator`; `@required` marks a field.                                         |
| `@resetOnDestroy`, `@resetIfDirtyOnly`        | `@resetOnDestroy` (resets only when dirty)                                                              |
| `@allowSubmitQueue`                           | Removed: a submit while submitting is ignored.                                                          |
| `@scrollToFirstVisibleError`                  | Always on, as focus: the first invalid control is focused.                                              |
| `@useEmberDataDirtyTracking`                  | Use `@formwright/warp-drive`.                                                                           |

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
replaced by normalized `data-test-fw-*` selectors and the harnesses in
`@formwright/test-support`:

```ts
// before
await fillIn('[data-test-field-for="user_email"] input', 'a@b.co')
// after
await form('signup').field('email').fillIn('a@b.co')
```
