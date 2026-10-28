---
'@ember-formwright/maskito': minor
---

A `phone` control, from the new `@ember-formwright/maskito/phone` entry point: a `type="tel"`
input masked per country by `@maskito/phone` and libphonenumber-js. It stores E.164
(`+12125550123`) or `null`, and shows the number formatted. `field.Control` takes `@country`,
`@strict`, `@national` and `@metadata`. `isValidPhone` checks a number in a validator, and
`formatPhone` shows one in inline forms. `PhoneHarness` drives it in tests, from
`@ember-formwright/maskito/test-support`. `@maskito/kit`, `@maskito/phone` and
`libphonenumber-js` are optional peers: only the phone entry point needs them.
