# @ember-formwright/layouts

Field layouts for Formwright, and a button bar.

```bash
npm install @ember-formwright/ember @ember-formwright/layouts
```

```ts
// app/app.ts
import { registerLayouts } from '@ember-formwright/layouts'
import '@ember-formwright/ember/theme.css'
import '@ember-formwright/layouts/layouts.css'

registerLayouts() // @layout="horizontal", "compact" and "checkbox-after"
```

```gts
import { Actions } from '@ember-formwright/layouts'

<Form @model={{@member}} @layout="horizontal" as |f|>
  <f.Field @for="name" @label="Name" />
  <f.Field @for="agree" @control="checkbox" @label="I agree" @layout="checkbox-after" />

  <Actions>
    <:left><f.Submit>Save</f.Submit><f.Reset>Cancel</f.Reset></:left>
    <:right><f.Button @onClick={{this.delete}}>Delete</f.Button></:right>
  </Actions>
</Form>
```

| Export            |                                                                                      |
| ----------------- | ------------------------------------------------------------------------------------ |
| `Horizontal`      | `horizontal`: the label in a left column (`--fw-label-width`), the rest on the right |
| `Compact`         | `compact`: label and control on one line; hint and errors wrap below                 |
| `CheckboxAfter`   | `checkbox-after`: the control, then its label. Groups keep their legend first        |
| `Actions`         | A bar with `<:left>` and `<:right>` blocks for the form's buttons                    |
| `registerLayouts` | Registers the three layouts by name                                                  |

The components can also be passed directly: `@layout={{Horizontal}}`.

Layouts only change structure. A purely visual change, such as a label column, is plain CSS
on `.fw-field`. To write your own layout, see `FieldLayoutSignature` in
`@ember-formwright/ember` and the guide's Layouts page.
