# @ember-formwright/ember

Declarative, accessible forms for Ember: one `<Form>`, one `<f.Field>`, any validator, any data
layer.

```bash
npm install @ember-formwright/ember
```

```gts
import { Form } from '@ember-formwright/ember'
import '@ember-formwright/ember/theme.css' // optional

<template>
  <Form @model={{@user}} @validator={{userSchema}} as |f|>
    <f.Field @for="email" @control="email" @label="Email" />
    <f.Submit />
  </Form>
</template>
```

Full documentation: the [repository README](https://github.com/joegaudet/ember-formwright#readme) and
the site, with a live demo, at **https://joegaudet.com/ember-formwright/**.
