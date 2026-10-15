# @ember-formwright/maskito

A masked text control for Formwright, powered by [Maskito](https://maskito.dev).

```bash
npm install @ember-formwright/ember @ember-formwright/maskito @maskito/core
```

```ts
// app/app.ts
import { registerMaskedControl } from '@ember-formwright/maskito'
registerMaskedControl() // @control="masked"
```

```gts
const phoneMask = { mask: ['(', /\d/, /\d/, /\d/, ')', ' ', /\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, /\d/] }

<f.Field @for="phone" @control="masked" @label="Phone" as |field|>
  <field.Control @mask={{phoneMask}} />
</f.Field>
```

The model receives the masked string. `@maskito/kit` generators (numbers, dates, phones) work
as `@mask`.
