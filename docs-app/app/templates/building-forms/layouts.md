# Layouts

A field renders its label, hint, control and errors in that order. For a different **look**,
CSS is enough: every field is one `div.fw-field`, so a label column or a tighter row is a
grid away (see [Theming](../going-further/theming.md#when-css-is-enough)). For a different
**structure** (a different order, wrappers, the label after the control), give the form a
layout.

```gts
<Form @model={{@member}} @layout="horizontal" as |f|>
  <f.Field @for="name" @label="Name" />
  <f.Field @for="agree" @control="checkbox" @label="I agree" @layout="checkbox-after" />
</Form>
```

- `@layout` on a `Form` applies to its fields and its nested forms. A `Field` can override it
  with its own `@layout`.
- A layout is a registered name or a component.
- `setDefaultLayout(nameOrComponent)` changes it for every form without one. Call it once at
  boot, like `setDefaultAdapter`.

## Shipped layouts

```bash
npm install @ember-formwright/layouts
```

```ts
// app/app.ts
import { registerLayouts } from '@ember-formwright/layouts'
import '@ember-formwright/layouts/layouts.css' // after the core theme

registerLayouts() // @layout="horizontal", "compact" and "checkbox-after"
```

### horizontal

The label in a column on the left (`--fw-label-width`, default `10rem`); the control, hint and
errors on the right. On narrow screens it stacks.

<Example @name="layouts-horizontal" @title="Labels in a column" />

### compact

Label and control on one line, for filter bars and settings rows. The hint and errors wrap
below.

<Example @name="layouts-compact" @title="A filter bar" />

### checkbox-after

The checkbox, then its label: the usual order for a single checkbox. Use it per field. A
group control (`radio`, `checkbox-group`) keeps its legend first.

<Example @name="layouts-checkbox-after" @title="Settings toggles" />

### Actions

Not a layout, but the bar most forms end with: `<Actions>` has `left` and `right` named blocks
for `<f.Submit>`, `<f.Reset>` and `<f.Button>`.

<Example @name="layouts-actions" @title="Save, cancel and delete" />

```gts
import { Actions } from '@ember-formwright/layouts'

<Actions>
  <:left><f.Submit>Save</f.Submit><f.Reset>Cancel</f.Reset></:left>
  <:right><f.Button @onClick={{this.delete}}>Delete</f.Button></:right>
</Actions>
```

## Writing your own

A layout is a component with `FieldLayoutSignature`. It gets two args:

- `@parts`: components already wired to the field. A layout places them; it never renders a
  label or an error itself.
- `@field`: read-only state (`id`, `controlName`, `isGroup`, `isInvalid`, `isDirty`,
  `disabled`, `required`).

| Part      | Renders                                                                           |
| --------- | --------------------------------------------------------------------------------- |
| `Label`   | `<label for>` the control, or the `<legend>` of a group. Nothing without `@label` |
| `Hint`    | The hint, with the id the control's `aria-describedby` points at                  |
| `Control` | Everything about the control: inline value, callout, the control, ✔ and ✘         |
| `Errors`  | The aria-live error region, with its id. Always rendered                          |
| `Group`   | A group control's `<fieldset>`; for any other control, just its content           |

Each part owns its ids, `aria-*` and `data-test-fw-*` attributes. A layout can rearrange the
parts, but it can't break accessibility or the test harnesses. You can add attributes (a
class) to every part but `Control`.

Two rules:

1. **Render the control as `<@parts.Control as |control|>{{yield control}}</@parts.Control>`.**
   That passes a field's block form on to it. A layout that renders `<@parts.Control />`
   ignores the block and shows the plain control.
2. **Put `Label` first inside `Group`.** For a group control, the `<legend>` must be the
   fieldset's first child.

Core keeps the outer `div.fw-field`, with its classes, `data-*` states, `data-test-fw-*`
attributes, `...attributes`, and the Enter/Escape handling. Inline editing, the callout and
confirm all live inside `Control`, so a layout never needs to know about them.

<Example @name="layouts-custom" @title="Errors above the control" />

```ts
import { registerLayout } from '@ember-formwright/ember'

registerLayout('stacked', Stacked) // then @layout="stacked"
```

<div class="callout">

**Coming from form-for**

`form.Label`, which let a caller place the label, becomes a layout: `Label` is one of its
parts. `FormButtons` with `left` and `right` slots is `<Actions>` with `<:left>` and `<:right>`.

</div>
