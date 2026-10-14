# Built-in controls

Pick a control with `@control`. Every control gets the same wiring from its field: an id the
label points at, the value, `onChange`, disabled/readonly/required, `aria-invalid` and
`aria-describedby`.

| `@control`                                                     | Renders                                         | Stores                                    |
| -------------------------------------------------------------- | ----------------------------------------------- | ----------------------------------------- |
| `input` (default), `email`, `password`, `url`, `tel`, `search` | `<input type="…">`                              | string                                    |
| `date`, `datetime`, `time`                                     | `<input type="date">`, `datetime-local`, `time` | string (ISO)                              |
| `color`                                                        | `<input type="color">`                          | string (`#rrggbb`)                        |
| `number`, `range`                                              | `<input type="number">`, `range`                | number, or `null` when empty              |
| `currency`                                                     | a text input formatted with `Intl.NumberFormat` | number, or `null`                         |
| `textarea`                                                     | `<textarea>`                                    | string                                    |
| `select`                                                       | `<select>`                                      | the option (or its key, with `@storeKey`) |
| `radio`                                                        | a `<fieldset>` of radios                        | the option (or its key)                   |
| `checkbox`                                                     | `<input type="checkbox">`                       | boolean                                   |
| `checkbox-group`                                               | a `<fieldset>` of checkboxes                    | an array of options (or keys)             |

## Text

<Example @name="controls-text" @title="Text-like inputs" @noModel={{true}} />

## Numbers and money

`number` and `range` store numbers (or `null` when cleared). `currency` shows the
amount formatted for its `@locale` and `@currency`, accepts typing in that locale (with its
decimal separator), and stores a number.

<Example @name="controls-numbers" @title="number, range, currency" />

## Long text

`@maxLength` caps the length, and `@showCount` shows a live counter that is announced politely.

<Example @name="controls-textarea" @title="textarea with a counter" />

## Choosing from options

`select`, `radio` and `checkbox-group` take `@options`: primitives or objects.

- **The key** identifies an option and becomes its `value` in the DOM. It is `@optionKey` (a
  property name or a function), or `id`, or `value`, or the option itself.
- **The label** is `@optionLabel`, or `label`, or `name`, or the option itself.
- **What's stored** is the option itself, unless `@storeKey` asks for just its key.
- **Disabled options** are objects with `disabled: true`.
- A value that isn't among the options still shows in a select, rather than silently picking
  another.

<Example @name="controls-select" @title="select" />

<Example @name="controls-radio" @title="radio" />

## Checkboxes

`checkbox` stores a boolean. `checkbox-group` stores an array, and `@max` caps how many can be
checked: once it's reached, the rest disable.

<Example @name="controls-checkboxes" @title="checkbox and checkbox-group" />

<div class="callout">

**Coming from ember-foxy-forms**

`ff-checkbox-select` is `checkbox-group`, `@selectionMax` is `@max`, `@idKey`/`@labelKey` are
`@optionKey`/`@optionLabel`, and `@storeAsPrimitive` is `@storeKey`. The comma-separated string
form of `@values` is gone: pass an array to `@options`. `ff-multiple-input` was removed; see
[custom controls](custom-controls.md) for editing an object with one control.

</div>
