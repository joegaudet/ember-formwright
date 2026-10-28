# Theming

Formwright renders plain, semantic markup with stable class names and state attributes. You
choose how much of the look you want:

- **The theme:** `import '@ember-formwright/ember/theme.css'`, then adjust it with custom properties.
- **Your own CSS:** skip the theme and style the `.fw-*` classes and `data-*` states.

## Custom properties

Every example in this guide has a **Theme** picker. Each preset is only a handful of these
properties, scoped to a class:

| Property                           | Default (light)              |                                 |
| ---------------------------------- | ---------------------------- | ------------------------------- |
| `--fw-font`                        | `inherit`                    | Font shorthand for forms        |
| `--fw-accent` / `--fw-accent-fg`   | `#4f46e5` / `#fff`           | Submit button, checked controls |
| `--fw-border`, `--fw-border-focus` | `#cfd3dc`, `#4f46e5`         | Control borders                 |
| `--fw-bg`, `--fw-fg`, `--fw-muted` | `#fff`, `#1b1d24`, `#626877` | Surfaces, text, hints           |
| `--fw-error`                       | `#c62828`                    | Error text and invalid borders  |
| `--fw-radius`                      | `8px`                        | Corner radius                   |
| `--fw-gap`, `--fw-field-gap`       | `0.375rem`, `1.25rem`        | Space within and between fields |
| `--fw-ring`                        | a 3px accent ring            | Focus ring                      |

Scope them to any element:

<Example @name="theming-custom" @title="A custom look in a few properties" @noModel={{true}} />

## Light and dark

The theme follows the operating system. To force a scheme for part of a page, as the
**light/dark** switch on these examples does, set `data-fw-scheme`:

```html
<div data-fw-scheme="dark">…forms here are dark…</div>
```

## When CSS is enough

Each field is one `div.fw-field`, holding its label, hint, control area and errors in that order.
A purely visual change is CSS on that element. Use a [layout](../building-forms/layouts.md)
only to change the structure: the order, or wrappers.

```css
/* A label column, without a layout */
.my-form .fw-field {
  grid-template-columns: 10rem 1fr;
}
.my-form .fw-field > :not(.fw-label) {
  grid-column: 2;
}
```

`@ember-formwright/layouts/layouts.css` styles the shipped layouts with the same custom
properties, plus `--fw-label-width` for `horizontal`.

## Styling without the theme

| Selector                                                               | On                                         |
| ---------------------------------------------------------------------- | ------------------------------------------ |
| `.fw-form`, `.fw-form--nested`                                         | The `<form>`; a nested form's `<fieldset>` |
| `.fw-field`, `.fw-field--<control>`                                    | Each field, by control name                |
| `.fw-label`, `.fw-hint`, `.fw-required`                                | Label, hint, the `*`                       |
| `.fw-control`, `.fw-input`, `.fw-select`, `.fw-textarea`               | Controls                                   |
| `.fw-errors`, `.fw-error`                                              | The error region and each message          |
| `.fw-button`, `.fw-button--submit`, `.fw-button--reset`                | Buttons                                    |
| `.fw-display`, `.fw-callout`, `.fw-confirm`                            | Inline editing                             |
| `[data-invalid]`, `[data-dirty]`, `[data-disabled]`, `[data-required]` | Field state                                |
| `[data-submitting]`, `[data-dirty]`                                    | Form state, on the `<form>`                |
| `[aria-busy="true"]`                                                   | A button whose action is running           |

`@ember-formwright/power-select/theme.css` gives power-select's trigger the same custom
properties: border, radius, focus ring, and the invalid and disabled states. Import it after
power-select's own CSS; it doesn't restyle the dropdown.

The other add-on controls do the same for theirs, each from its package's `theme.css`:
`@ember-formwright/power-calendar` (the trigger and the calendar, so power-calendar's own CSS
isn't needed; size it with `--fw-calendar-cell`), `@ember-formwright/file-upload` (the drop zone
and file list) and `@ember-formwright/tiptap` (the toolbar and editor). Import each after the
core theme.

<div class="callout">

**Coming from ember-foxy-forms**

The BEM option (`useBemClass`), CSS grid areas (`useGridTemplate`) and configurable class
lists are gone. Use the classes above, and for grids, lay out fields with your own CSS: each
field is one element.

</div>
