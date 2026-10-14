import { Form } from '@formwright/ember'

const user = { name: '', email: '' }
const requireEmail = m => (m.email ? {} : { email: ['Email is required'] })

<template>
  <h1>Formwright in a classic app</h1>
  <Form @model={{user}} @name="signup" @validator={{requireEmail}} as |f|>
    <f.Field @for="name" @label="Name" />
    <f.Field @for="email" @control="email" @label="Email" />
    <f.Submit />
  </Form>
</template>
