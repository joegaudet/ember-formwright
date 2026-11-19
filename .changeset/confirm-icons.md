---
'@ember-formwright/ember': patch
---

The apply and cancel buttons of `@requireConfirm` and `@inline` fields draw a check and a cross
as inline SVG (`.fw-icon`, stroked in `currentColor`) instead of the ✔ and ✘ characters, so
they look the same in every font and follow the theme's colors. The buttons keep their
`aria-label`s, and the icons are hidden from assistive technology.
