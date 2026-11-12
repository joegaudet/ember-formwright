---
'@ember-formwright/ember': major
'@ember-formwright/maskito': major
'@ember-formwright/file-upload': major
'@ember-formwright/power-select': major
'@ember-formwright/power-calendar': major
'@ember-formwright/tiptap': major
---

Fields type their control against their path. `@control` must be a control that stores what the
path holds, and a field takes only its control's args, typed for that path. `ControlSignature`
is split into the wiring every control gets and its own args, and registered names are declared
in `FormwrightControls` (or `FormwrightChoiceControls<T>`, for controls whose value follows the
path). The add-ons declare their default names. See MIGRATION.md.
