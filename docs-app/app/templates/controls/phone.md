# Phone

`@ember-formwright/maskito/phone` adds a `phone` control: a phone number input masked as it is
typed by [`@maskito/phone`](https://maskito.dev/addons/phone), with the rules for each country
from [libphonenumber-js](https://gitlab.com/catamphetamine/libphonenumber-js). It ships in
`@ember-formwright/maskito`, as a separate entry point, so the masked control doesn't pull in
the phone metadata.

```bash
npm install @ember-formwright/maskito @maskito/core @maskito/kit @maskito/phone libphonenumber-js
```

```ts
// app/app.ts
import { registerPhoneControl } from '@ember-formwright/maskito/phone'

registerPhoneControl() // @control="phone"
```

## Typing and storing

The model stores the number in [E.164](https://en.wikipedia.org/wiki/E.164) form,
`+12125550123`, whatever the input shows; an empty input stores `null`. A stored number is
shown formatted. While a number is being typed, the model holds its digits so far, with the `+`.

<Example @name="controls-phone" @title="phone, in three countries" />

Give these to `field.Control`:

| Argument    | Default       | What it does                                                                                                                                                                               |
| ----------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `@country`  | `US`          | The country whose numbers are typed, as an ISO 3166 code (`GB`, `FR`, ...). A national number is converted: `07700 900123` in `GB` becomes `+447700900123`.                                |
| `@strict`   | `true`        | Only numbers of `@country`, with its calling code fixed in front. With `false`, any country's number, starting with `+`; `@country` then only reads pasted or autofilled national numbers. |
| `@national` | `false`       | Strict mode only: show the national format, `(212) 555-0123`, without the calling code. The model still stores E.164.                                                                      |
| `@metadata` | the `min` set | libphonenumber-js metadata, if you load another set (`max`, `mobile`, or your own).                                                                                                        |

The input is `type="tel"` with `autocomplete="tel"`, so phones show a dial pad and browsers can
fill in the user's number. Maskito tidies pasted and autofilled numbers too.

## Validating

The mask limits a number's length, but it can't tell a whole number from a partial one.
`isValidPhone(value, country?)` checks a stored number with libphonenumber-js, so use it in
your validator:

```ts
import { isValidPhone } from '@ember-formwright/maskito/phone'

const schema = z.object({
  phone: z
    .string()
    .nullable()
    .refine(v => isValidPhone(v), 'That number looks off'),
})
```

It returns `false` for `null` and empty strings. It checks against the `min` metadata, which
checks a number's length for its country; pass the `max` metadata as the third argument to
check its digits too.

## Inline editing

In `@inline` forms, give the field `formatPhone` as its `@format`, so the value shows formatted,
not as E.164:

```gts
import { formatPhone } from '@ember-formwright/maskito/phone'

<Form @model={{@contact}} @inline={{true}} as |f|>
  <f.Field @for="phone" @control="phone" @label="Phone" @format={{formatPhone}} />
</Form>
```

It shows the number in international format (`+44 7911 123456`), and anything that doesn't
parse as it is.

## Testing

`PhoneHarness`, from `@ember-formwright/maskito/test-support`, adds `fillIn(text)`, `clear()`,
`value` (the text shown, masked) and `input` to
[`FieldHarness`](../going-further/testing.md#field-harnesses). `fillIn` replaces the text the
way a paste or autofill does, and lets Maskito shape it, so the model gets what the mask kept.

```ts
import { PhoneHarness } from '@ember-formwright/maskito/test-support'

class ContactForm extends FormHarness {
  @field(PhoneHarness) declare phone: PhoneHarness
}

await contact.phone.fillIn('2125550123')
assert.strictEqual(contact.phone.value, '+1 212 555-0123')
assert.strictEqual(model.phone, '+12125550123')
```

<div class="callout">

**Known limits**

- In strict mode a stored number from another country is shown through `@country`'s mask, so
  it may show wrongly. Use `@strict={{false}}` when numbers can come from anywhere.
- There is no country picker. Pick `@country` from another field if you need one.
- `formatPhone` and `isValidPhone` load the `min` metadata (about 80 kB, shared with the mask).

</div>
