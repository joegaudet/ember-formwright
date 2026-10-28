# @ember-formwright/power-select

Searchable, async and multiple selects for Formwright, powered by
[ember-power-select](https://ember-power-select.com) 9.

```bash
npm install @ember-formwright/ember @ember-formwright/power-select ember-power-select ember-basic-dropdown ember-concurrency
```

```ts
// app/app.ts
import { registerPowerSelectControls } from '@ember-formwright/power-select'
import 'ember-basic-dropdown/styles'
import 'ember-power-select/styles'
import '@ember-formwright/power-select/theme.css' // optional; after the Formwright theme

registerPowerSelectControls() // @control="power-select" and @control="power-select-multiple"
```

Render `<BasicDropdownWormhole />` (from `ember-basic-dropdown/components/basic-dropdown-wormhole`)
once in your application template; dropdowns render into it. In tests, add
`<div id="ember-basic-dropdown-wormhole"></div>` next to `#ember-testing` in `tests/index.html`.

```gts
<f.Field @for="owner" @control="power-select" @label="Owner"
         @options={{this.users}} @optionLabel="name" as |field|>
  <field.Control @searchEnabled={{true}} @allowClear={{true}} as |user|>
    {{user.name}} <small>{{user.email}}</small>
  </field.Control>
</f.Field>

{{! async search: options come from @search, so give inline mode a @format }}
<f.Field @for="owner" @control="power-select" @format={{this.userName}} as |field|>
  <field.Control @search={{this.searchUsers}} @searchEnabled={{true}} />
</f.Field>
```

`power-select-multiple` stores an array: of options, or of keys with `@storeKey`, like
`checkbox-group`. `@options`, `@optionKey`, `@optionLabel` and `@storeKey` work as they do for
`select`. Other power-select args given to `field.Control` are forwarded (`@search`,
`@searchEnabled`, `@allowClear`, `@renderInPlace`, `@matcher`, `@searchField`, ...), and its
block renders each option. Without `@matcher` or `@searchField`, search matches the option's
label.

## Testing

```ts
import { PowerSelectHarness } from '@ember-formwright/power-select/test-support'

class TaskForm extends FormHarness {
  @field(PowerSelectHarness) declare owner: PowerSelectHarness
}

await task.owner.search('ada') // waits for @search
await task.owner.select('Ada Lovelace')
assert.deepEqual(task.owner.selected, ['Ada Lovelace'])
await task.owner.clear()
```

It also has `remove(text)` (multiple), `options()`, `isOpen` and `trigger`.

## Behaviour and known limits

- **Focus.** Inline and confirm modes focus the trigger: core focuses the element with the
  field's id.
- **Callouts.** In `@inline @callout` forms the control sets `@renderInPlace={{true}}`, so the
  dropdown is inside the popover (the top layer): visible, and a click on an option doesn't
  close the callout. The theme lets the popover overflow for it.
- **Keyboard.** While the dropdown is open, Enter and Escape belong to it and don't reach the
  field: with `@requireConfirm` or `@inline`, Enter on an option doesn't commit, and the first
  Escape closes the dropdown instead of cancelling the edit.
- **Async options.** Without `@options`, inline mode shows an object value by its label
  (`@optionLabel`, `label` or `name`). Give the field a `@format` for anything else.
- **`@storeKey` with `@search`.** A stored key can't be mapped back to an option that hasn't
  been searched for. Pass that option as `@selectedOption` (an array for multiple); options
  chosen afterwards are remembered. Without it, the trigger shows the placeholder.
- **Labels.** The trigger is a `div role="combobox"`, which `<label for>` doesn't name, so the
  control passes the field's `@label` as `@ariaLabel`. Clicking the label doesn't open the
  dropdown.
- **Native submit.** power-select renders no `<input name>`; the wrapper carries
  `data-fw-name` with the field's path.
- **Ember and power-select versions.** Ember 6.12+ and ember-power-select 9 only.
