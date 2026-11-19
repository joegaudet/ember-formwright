# Catalogs

A catalog holds your translations of Formwright's strings, in your i18n library's format. Build
one from the messages each package exports, then [register a translator](translation.md) that
reads it.

## The messages

Each package exports its messages as data, at `./messages`, so a tool can build a catalog from
them:

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

## Building a catalog

msgid's CLI builds a catalog from those modules:

```sh
# gettext: a template to translate, then a .po file converted for msgid/gettext
msgid pot @ember-formwright/ember/messages @ember-formwright/file-upload/messages > formwright.pot
msgid po2json pl.po --out translations/pl.json

# ICU (FormatJS, ember-intl, Lingui) and i18next source catalogs
msgid icu @ember-formwright/ember/messages --out translations/en.json
msgid i18next @ember-formwright/ember/messages --out locales/en/translation.json
```

## Validation messages

Error messages come from your validator, not from Formwright, so translate them there. zod has
locales (`z.config(z.locales.fr())`), and valibot has `@valibot/i18n` with
`v.setGlobalConfig({ lang: 'fr' })`. A plain validator function returns whatever strings you
give it.

The add-ons' own dependencies have strings of their own: pass ember-power-select's
`@searchMessage`, `@noMatchesMessage` and `@loadingMessage` to its `field.Control`. Enum labels
from `enumOptions` come from real-enums, which takes its own translator.
