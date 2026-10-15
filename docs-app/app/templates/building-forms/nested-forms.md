# Nested forms

A form can contain forms for related models: a product and its warehouse, an order and its
address. Use `f.Form`. It renders a `<fieldset>` (forms can't nest in HTML), with `@legend` as
its legend.

<Example @name="nested-forms" @title="A product and its warehouse" />

## How they behave

- **One submit.** Submitting the root validates every nested form. If any is invalid, nothing
  saves.
- **Parents save first.** The root saves its model, then each nested form that needs saving,
  level by level. A child can rely on its parent already having an id.
- **Only what changed.** A nested form saves when one of its fields changed or, with
  `@ember-formwright/warp-drive`, when its record is new or deleted.
- **Shared settings.** `@disabled`, `@readonly`, `@inline`, `@requireConfirm` and `@adapter`
  pass down, and a nested form can override them.
- **Own hooks.** A nested form's `@didSubmit` and `@failedSubmit` hear about its own save.
- **Own tests.** In a harness, declare it with `@form(ChildHarness)`. See
  [Testing](../going-further/testing.md).

<div class="callout">

**Coming from ember-foxy-forms**

Instead of `<FormFor @parentForm={{f.self}}>`, use `<f.Form>`. `@childDidSubmit` and
`@childFailedSubmit` on the parent are replaced by `@didSubmit` and `@failedSubmit` on the
child.

</div>
