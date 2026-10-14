import { Page } from 'kolay/components'

<template>
  <Page>
    <:pending>
      <p class="guide-loading" role="status">Loading…</p>
    </:pending>
    <:error as |error|>
      <div class="guide-error" role="alert">{{String error}}</div>
    </:error>
    <:success as |Prose|>
      <article class="guide-prose"><Prose /></article>
    </:success>
  </Page>
</template>
