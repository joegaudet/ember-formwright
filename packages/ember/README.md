# @formwright/ember

Declarative, accessible forms for Ember: one `<Form>`, one `<f.Field>`, any validator, any data
layer.

```bash
npm install @formwright/ember
```

```gts
import { Form } from '@formwright/ember'
import '@formwright/ember/theme.css' // optional

<template>
  <Form @model={{@user}} @validator={{userSchema}} as |f|>
    <f.Field @for='email' @control='email' @label='Email' />
    <f.Submit />
  </Form>
</template>
```

Full documentation: the [repository README](https://github.com/joegaudet/formwright#readme) and
the site, with a live demo, at **https://joegaudet.com/formwright/**.
