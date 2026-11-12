# Translation

Formwright's own strings (the Submit and Reset buttons, the ✔ and ✘ of a confirmed field, the
file upload's prompts, the rich-text toolbar) are English by default. Register one translator
and every one of them goes through it, in every Formwright package.

## Registering a translator

A translator is an object with a `locale` and a `t` function. Formwright looks it up as
`translator:main` on the owner, so register it in an instance initializer:

```ts
// app/instance-initializers/translator.ts
import type ApplicationInstance from '@ember/application/instance'
import { format, type Translator } from '@ember-formwright/ember'

export function initialize(owner: ApplicationInstance) {
  const intl = owner.lookup('service:intl')
  const translator: Translator = {
    get locale() {
      return intl.primaryLocale
    },
    t: (message, values) =>
      intl.exists(message.id) ? intl.t(message.id, values) : format(message, values),
  }
  owner.register('translator:main', translator, { instantiate: false })
}

export default { initialize }
```

That one is for ember-intl; any i18n library works the same way. `t` receives a message, with
its stable `id` (`formwright.form.submit`), its English `message` (`Submit`, with `{name}`
placeholders) and a `description` for translators, plus the placeholder values. `format`
returns the English text, for messages your catalog doesn't have yet. Make `locale` tracked (a
service's tracked property, as here) and changing it re-renders every string.

Libraries that follow the same contract, such as ember-joinery, read the same `translator:main`,
so one registration translates them all.

<div class="callout">

Without a translator, nothing changes: every string is the English it always was.

</div>

## The messages

Each package exports its messages as data, so a tool can build a catalog from them:

```ts
import { messages } from '@ember-formwright/ember/messages'
import { messages as fileUpload } from '@ember-formwright/file-upload/messages'
import { messages as richText } from '@ember-formwright/tiptap/messages'
import { messages as datePicker } from '@ember-formwright/power-calendar/messages'
```

| Package          | Ids                                                                                                                                            |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `ember`          | `formwright.form.submit`, `formwright.form.reset`, `formwright.field.apply`, `formwright.field.cancel`                                         |
| `file-upload`    | `formwright.fileUpload.` `chooseFile`, `chooseFiles`, `dropToAdd`, `orDropHere`, `notAccepted`, `remove`, `retry`, `uploading`, `uploadFailed` |
| `tiptap`         | `formwright.richText.` `toolbar`, `bold`, `italic`, `strike`, `heading`, `bulletList`, `orderedList`, `blockquote`, `undo`, `redo`             |
| `power-calendar` | `formwright.datePicker.trigger` (the trigger's name, `{label}: {value}`)                                                                       |

The other packages (maskito, power-select, layouts, warp-drive, changeset, real-enums,
test-support) render no strings of their own.

## Changing one string

An argument beats the translator. Use one to change a string in one place:

| Where                         | Arguments                                                                                                                                  |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `<f.Submit>`, `<f.Reset>`     | `@text`, or a block                                                                                                                        |
| `<f.Field>`                   | `@applyLabel`, `@cancelLabel`: the accessible names of ✔ and ✘                                                                             |
| file upload's `field.Control` | `@prompt`, `@dropLabel`, `@dropHint`, `@retryLabel`; `@removeLabel`, `@uploadingLabel` and `@rejectedLabel` take a function of the name(s) |
| rich text's `field.Control`   | `@toolbarLabel`, and `@toolLabels`, by tool: `{ bold: 'Strong' }`                                                                          |

<Example @name="translation" @title="Labels in your own words" />

## Validation messages

Error messages come from your validator, not from Formwright, so translate them there. zod has
locales (`z.config(z.locales.fr())`), and valibot has `@valibot/i18n` with
`v.setGlobalConfig({ lang: 'fr' })`. A plain validator function returns whatever strings you
give it.

The add-ons' own dependencies have strings of their own: pass ember-power-select's
`@searchMessage`, `@noMatchesMessage` and `@loadingMessage` to its `field.Control`. Enum labels
from `enumOptions` come from real-enums, which takes its own translator.

## Testing

`@ember-formwright/test-support` has a pseudo-locale translator: it wraps each string in `⟦ ⟧`
and accents it, so a string that skipped the translator stands out.

```ts
import { registerTranslator, pseudoTranslator } from '@ember-formwright/test-support'

test('every string is translated', async function (assert) {
  registerTranslator(pseudoTranslator) // before render
  await render(<template><SignupForm /></template>)
  assert.dom('[data-test-fw-submit]').hasText('⟦Śũƀɱĩţ⟧')
})
```
