---
'@ember-formwright/changeset': patch
'@ember-formwright/ember': patch
'@ember-formwright/file-upload': patch
'@ember-formwright/power-calendar': patch
'@ember-formwright/test-support': patch
'@ember-formwright/tiptap': patch
---

Type checks in package source use `@sindresorhus/is` (`isString`, `isFunction`, …) instead of `typeof`, and a lint rule keeps it that way. `@sindresorhus/is` is a new runtime dependency. `isNumber` rejects `NaN`, so a `NaN` reaching a numeric check now takes the non-number branch.
