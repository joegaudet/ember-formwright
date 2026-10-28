# Power select

`@ember-formwright/power-select` adds searchable, async and multiple selects, built on
[ember-power-select](https://ember-power-select.com) 9.

```bash
npm install @ember-formwright/power-select ember-power-select ember-basic-dropdown ember-concurrency
```

```ts
// app/app.ts
import { registerPowerSelectControls } from '@ember-formwright/power-select'
import 'ember-basic-dropdown/styles'
import 'ember-power-select/styles'
import '@ember-formwright/power-select/theme.css' // optional: follows the Formwright theme

registerPowerSelectControls() // @control="power-select" and @control="power-select-multiple"
```

Dropdowns render into a wormhole. Put one in your application template, as power-select's own
docs describe:

```gts
import BasicDropdownWormhole from 'ember-basic-dropdown/components/basic-dropdown-wormhole'

<template>
  {{outlet}}
  <BasicDropdownWormhole />
</template>
```

## Searchable and multiple

`@options`, `@optionKey`, `@optionLabel` and `@storeKey` work as they do for `select` (see
[choosing from options](./built-in-controls.md#choosing-from-options)).
`power-select-multiple` stores an array, like `checkbox-group`. Any other power-select arg
given to `field.Control` is passed on: `@searchEnabled`, `@allowClear`, `@renderInPlace`,
`@matcher`, `@searchField`, `@closeOnSelect`, `@onOpen`, ... The block renders each option, and
the selected one in the trigger. Without a block, an option shows its label, and search matches
on that label.

<Example @name="controls-power-select" @title="power-select and power-select-multiple" />

The field wires power-select up for you:

| Field                                 | power-select                                                        |
| ------------------------------------- | ------------------------------------------------------------------- |
| its id, so `<label for>` finds it     | `@triggerId`                                                        |
| `@label`                              | `@ariaLabel`, so the trigger has an accessible name                 |
| hint and errors                       | `@ariaDescribedBy`                                                  |
| invalid, `@required`                  | `@ariaInvalid`, `@required`                                         |
| `@disabled`, `@readonly`              | `@disabled` (power-select has no read-only state, like `select`)    |
| the stored value                      | `@selected`, the option the value or its key stands for             |
| `@onChange(selection, select, event)` | the field's change, as the option or its key (`@storeKey`)          |
| `@inline @callout`                    | `@renderInPlace={{true}}`, so the dropdown stays inside the popover |

## Options from a search

Without `@options`, give the control `@search`: it gets the typed text and returns (a promise
of) the options. Inline mode shows the value without its options, so give the field a
`@format`. Without one, an object value shows its label (`@optionLabel`, `label` or `name`).

<Example @name="controls-power-select-async" @title="Async search in a callout" />

With `@storeKey` and `@search`, the stored key has no options to be looked up in. Pass the
option it stands for as `@selectedOption` (an array for a multiple select). The control
remembers options chosen after that.

```gts
<f.Field @for="ownerId" @control="power-select" @storeKey={{true}} as |field|>
  <field.Control @search={{this.searchUsers}} @selectedOption={{this.owner}} />
</f.Field>
```

## Keyboard

While the dropdown is open, Enter chooses the highlighted option and Escape closes the
dropdown. Neither reaches the field. So with `@requireConfirm` or `@inline`, choosing with
Enter doesn't commit, and the first Escape closes the dropdown rather than cancelling the edit.
Once it is closed, Enter commits and Escape cancels, as in any field.

## Testing

`PowerSelectHarness`, from `@ember-formwright/power-select/test-support`, drives these fields
with power-select's own test helpers. It adds `select(text)`, `search(text)`, `clear()`,
`remove(text)`, `options()`, `selected`, `isOpen` and `trigger` to
[`FieldHarness`](../going-further/testing.md#field-harnesses). Each example's **Test** tab uses
it.

<div class="callout">

**Known limits**

- The trigger is a `div` with `role="combobox"`, so the field's `<label for>` gives it no name
  by itself. The control passes `@label` as `@ariaLabel` instead, and clicking the label
  doesn't open the dropdown.
- Power-select doesn't submit with a native `<form>`: there is no `<input name>`. The control
  sets `data-fw-name` with the field's path.

</div>
