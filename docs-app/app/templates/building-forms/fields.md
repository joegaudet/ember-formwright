# Fields

A field binds one model path to one control and renders everything around it: the label,
an optional hint, the control, and its errors. Each part is wired for assistive technology.

<Example @name="field-anatomy" @title="Label, hint, placeholder, required, format" />

## Arguments

| Argument                                              |                                                                                                                 |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `@for`                                                | The model path: `"email"`, `"address.city"`, `"items[0].name"`.                                                 |
| `@label`                                              | The field's `<label>`, or `<legend>` for group controls (radio, checkbox group).                                |
| `@hint`                                               | Help text under the label. The control is `aria-describedby` it.                                                |
| `@placeholder`                                        | Passed to the control; in inline mode, shown when there's no value.                                             |
| `@required`                                           | Marks the control `required` and shows `*`. Validation is still the validator's job.                            |
| `@control`                                            | A control name (`"email"`) or a component. Default `"input"`. See [Controls](../controls/built-in-controls.md). |
| `@options`, `@optionKey`, `@optionLabel`, `@storeKey` | Options for select, radio and checkbox group.                                                                   |
| `@min`, `@max`, `@step`                               | Bounds for number, range and date controls; `@max` also caps a checkbox group.                                  |
| `@maxLength`, `@showCount`                            | Length cap and counter for text controls.                                                                       |
| `@currency`, `@locale`                                | For the currency control.                                                                                       |
| `@disabled`, `@readonly`, `@requireConfirm`           | Override the form's setting for this field.                                                                     |
| `@format`                                             | Formats the value shown in inline mode.                                                                         |

## Typed paths and values

In a `.gts` template checked by Glint, a field is typed by the form's `@model`. `@for` must
be one of the model's paths, so a typo, a nested key that doesn't exist or a method name
fails `ember-tsc`. The path then types what the field hands back: its block's `value` and the
value `@format` receives.

```
<Form @model={{this.account}} as |f|>
  <f.Field @for="email" />                        {{! ok }}
  <f.Field @for="address.city" />                 {{! ok }}
  <f.Field @for="items.0.name" />                 {{! ok, so is items[0].name }}
  <f.Field @for="emial" />                        {{! type error }}
  <f.Field @for="seats" @format={{formatSeats}} /> {{! formatSeats gets a number }}
  <f.Field @for="name" as |field|>
    {{field.value}}                               {{! a string }}
  </f.Field>
</Form>
```

The same types reach the rest of the form. `f.state.model` is the model, and
`f.state.errors` and `@didNotSubmit` get an `ErrorMap<Model>`, keyed by the model's paths.
`@onChange(path, value, model)` types `value` by `path`. Two types are exported for your own
code: `Path<Model>`, the union of paths, and `PathValue<Model, Path>`, the type at a path.

Paths go five levels deep, and stop at `Date`, `Map`, `Set` and other built-ins. A model typed
loosely (`any`, `object`, or with an index signature such as `Record<string, unknown>`)
accepts any string and gives `unknown` values, as do loose-mode `.hbs` templates. Controls
aren't typed against values: whether a control suits the value at its path is still up to
you.

## What a field renders

```html
<div class="fw-field fw-field--email" data-test-fw-field="email" data-invalid data-required>
  <label class="fw-label" for="fw-12">Email<span class="fw-required">*</span></label>
  <p class="fw-hint" id="fw-12-hint">We never share it.</p>
  <div class="fw-control-area">
    <input
      id="fw-12"
      type="email"
      aria-invalid="true"
      aria-describedby="fw-12-hint fw-12-errors"
      required
    />
  </div>
  <div class="fw-errors" id="fw-12-errors" aria-live="polite">
    <ul>
      <li class="fw-error">That email looks off</li>
    </ul>
  </div>
</div>
```

The `data-*` states (`data-dirty`, `data-invalid`, `data-disabled`, `data-required`) are there
for styling, and the `data-test-fw-*` attributes for tests.

## Your own layout: the block form

Give a field a block and it yields a `Control` that is already wired to the field's id, value
and errors. Pass it control-specific arguments, or wrap it in your own markup. The label, hint
and errors still render around it.

<Example @name="field-layout" @title="Wrapping the control" />

The block also yields `id`, `value`, `errors` and `isInvalid`, so your markup can follow the
field's state.

<div class="callout">

**Coming from ember-foxy-forms**

`@using` is now `@control`, `@infoText` is `@hint`, and `@formatValue` is `@format`.
`@displayValueComponent` is replaced by `@format` or the block form. `@valueTooltip` and
`@editText` are gone: put that text in your own markup, or in `@hint`. Composite fields (an
array `@for` with `@withMapping`) are now a control bound to an object; see
[Custom controls](../controls/custom-controls.md).

</div>
