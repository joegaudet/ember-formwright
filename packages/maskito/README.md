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

## Phone

`@ember-formwright/maskito/phone` adds a `phone` control, masked per country by
[`@maskito/phone`](https://maskito.dev/addons/phone) and libphonenumber-js. Its peers are
optional: the `masked` control above doesn't need them.

```bash
npm install @maskito/kit @maskito/phone libphonenumber-js
```

```ts
// app/app.ts
import { registerPhoneControl } from '@ember-formwright/maskito/phone'
registerPhoneControl() // @control="phone"
```

```gts
import { formatPhone, isValidPhone } from '@ember-formwright/maskito/phone'

const schema = z.object({
  phone: z.string().nullable().refine(v => isValidPhone(v), 'That number looks off'),
})

<f.Field @for="phone" @control="phone" @label="Phone" />
<f.Field @for="mobile" @control="phone" @label="Mobile" @format={{formatPhone}} as |field|>
  <field.Control @country="GB" />
</f.Field>
```

The model stores E.164 (`+12125550123`), or `null` when empty, and the input shows it formatted.
`field.Control` takes `@country` (ISO code, default `US`), `@strict` (default `true`: only
`@country`'s numbers, its calling code fixed in front; `false` takes any country's, starting
with `+`), `@national` (strict mode: show `(212) 555-0123`) and `@metadata` (libphonenumber-js
metadata; default `min`).

- `isValidPhone(value, country?, metadata?)` checks a stored number, for validators. With the
  default `min` metadata it checks the number's length for its country.
- `formatPhone(value)` shows a stored number in international format, for `@format` in inline
  forms.

### Testing

```ts
import { PhoneHarness } from '@ember-formwright/maskito/test-support'

class ContactForm extends FormHarness {
  @field(PhoneHarness) declare phone: PhoneHarness
}

await contact.phone.fillIn('2125550123') // like a paste: Maskito shapes it
assert.strictEqual(contact.phone.value, '+1 212 555-0123')
assert.strictEqual(model.phone, '+12125550123')
```

### Known limits

- In strict mode a stored number from another country shows through `@country`'s mask. Use
  `@strict={{false}}` when numbers can come from anywhere.
- No country picker; bind `@country` to another field if you need one.
