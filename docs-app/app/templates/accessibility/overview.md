# Accessibility

Formwright wires up the parts of a field that assistive technology reads: the label, the hint,
the errors and the invalid state. You give each field a label; Formwright does the rest.

## What every field gets

| Part        | What Formwright renders                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------------------- |
| Label       | `<label for>` pointing at the control. A required field's `*` is `aria-hidden`; the control has `required`.     |
| Hint        | A paragraph with its own id. The control's `aria-describedby` points at it.                                     |
| Errors      | A region with `aria-live="polite"`, always rendered, so errors are announced as they appear.                    |
| Invalid     | While a field has errors, its control has `aria-invalid="true"` and `aria-describedby` adds the errors' id.     |
| Groups      | `radio` and `checkbox-group` render a `<fieldset>`, named by a `<legend>`. The fieldset has `aria-describedby`. |
| Inline edit | The value shown before editing is a `<button>` with `aria-expanded`.                                            |

The add-on controls (power-select, date picker, phone, file upload, rich text) pass
`aria-invalid` and `aria-describedby` to their own focusable element the same way.

## A failed submit

When a submit fails validation, focus moves to the first control with `aria-invalid="true"`, and
each field's error region announces its message. Send this form empty:

<Example @name="accessibility" @title="Focus and announced errors" />

## Built-in strings

The ✓ and ✕ of a confirmed field are icon buttons. Their accessible names are "Apply" and
"Cancel", set with `@applyLabel` and `@cancelLabel`, and they go through your translator like
every other built-in string. See [Translation](../internationalization/translation.md).

A textarea with `@showCount` shows its character count in an `aria-live="polite"` region.

## What your app owns

- **A label for every field.** Without `@label`, Formwright renders no label. Give the control a
  name some other way, or the axe audit fails.
- **Custom controls.** A [custom control](../controls/custom-controls.md) receives `@id`,
  `@invalid` and `@describedBy`. Put them on its focusable element as `id`, `aria-invalid` and
  `aria-describedby`; focus on a failed submit finds the control by `aria-invalid`.
- **Contrast.** Every example in this guide passes axe, colour contrast included, with the
  theme loaded. If you [re-theme](../going-further/theming.md),
  check your own.

<div class="callout">

A `checkbox-group` does not mark its checkboxes `aria-invalid`, so a failed submit does not move
focus to it. Its errors are still announced.

</div>

## Joinery

[Joinery](https://joegaudet.com/ember-joinery/) renders Formwright fields with its own
components through `@ember-joinery/formwright`. Those controls follow
[Joinery's accessibility](https://joegaudet.com/ember-joinery/guide/accessibility/index.md).

## Testing

End every form test with an axe audit. See [Accessibility testing](testing.md).
