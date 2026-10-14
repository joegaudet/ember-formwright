# Introduction

Formwright is a form library for Ember. You describe a form as one `<Form>` and one
`<f.Field>` per value. It wires up everything else: labels tied to their inputs, hints and
error messages that screen readers announce, `aria-invalid` at the right moment, dirty state,
reset, and saving nested records in the right order.

<Example @name="getting-started" @title="A first form" />

Every example in this guide is live. Type into it and watch **The model, live** change. The
**Template** tab shows the example's exact source, and **Test** shows the test that covers it.

## Install

```bash
npm install @ember-formwright/ember
npm install --save-dev @ember-formwright/test-support
```

Formwright works with Ember 6.12 LTS and 7, in Vite (Embroider) apps and classic ember-cli
apps. It is a v2 addon: import what you use into `.gjs`/`.gts` files.

```ts
import { Form } from '@ember-formwright/ember'

// Optional: a theme driven by --fw-* custom properties. See "Theming".
import '@ember-formwright/ember/theme.css'
```

## How it works

Using Formwright takes three steps, the same three as ember-foxy-forms:

1. **Give the form a model.** It can be a plain object, a class with `@tracked` fields, or a
   WarpDrive / ember-data record.
2. **Tell each field which value it edits**, with `@for="email"` or a nested path such as
   `@for="address.city"`.
3. **Pick a control** with `@control`: `email`, `select`, `checkbox`, … or your own component.

The form reads values from the model, writes changes back, validates, and saves.

<div class="callout callout--tip">

**Coming from ember-foxy-forms?**

Formwright is its successor. The ideas carry over, but it uses named arguments only
(`@for="name"`, not positional params), `.gts` imports instead of globally resolved
components, and any Standard Schema validator. The
[migration guide](https://github.com/joegaudet/formwright/blob/main/MIGRATION.md) maps every
old component and argument to its replacement.

</div>
