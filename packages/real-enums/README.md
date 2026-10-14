# @formwright/real-enums

Use [real-enums](https://joegaudet.com/real-enums/) classes as Formwright options.

```bash
npm install @formwright/ember @formwright/real-enums real-enums
```

Formwright's controls already understand enum members as options (key `value`, text `label`).
This package adds:

```gts
import { enumOptions, enumValue, enumLabel } from '@formwright/real-enums'

{{! every member, or a filtered list }}
<f.Field @for="state" @control="select" @options={{enumOptions OrderState}} />
<f.Field @for="state" @control="radio"
  @options={{enumOptions OrderState except=(array OrderState.Cancelled)}} />

{{! the model stores the raw string ("shipped") instead of the member }}
<f.Field @for="state" @control="select" @options={{enumOptions OrderState}}
  @optionKey={{enumValue}} @storeKey={{true}} />

{{! inline editing shows the label for a raw value }}
<f.Field @for="state" @format={{enumLabel OrderState}} />
```

Requires real-enums 2 (an optional peer: the helpers only read `Enum.values`, `value` and
`label`).
