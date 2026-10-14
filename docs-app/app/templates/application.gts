import { PageNav } from 'kolay/components'

const LOGO = `${import.meta.env.BASE_URL}logo.svg`

/** On phones the contents start collapsed, so the page isn't pushed below the fold. */
const WIDE = typeof matchMedia === 'function' && matchMedia('(min-width: 861px)').matches

const TITLES: Record<string, string> = {
  api: 'API reference',
  'built in controls': 'Built-in controls',
}

/** "custom-controls" → "Custom controls" */
function title(name: string): string {
  const key = name.replace(/\.md$/, '').replaceAll('-', ' ')
  if (TITLES[key]) return TITLES[key]
  const words = name.replace(/\.md$/, '').replaceAll('-', ' ')
  return words.charAt(0).toUpperCase() + words.slice(1)
}

<template>
  <header class="guide-header">
    <a class="guide-brand" href="https://joegaudet.com/formwright/">
      <img src={{LOGO}} alt="" width="26" height="26" />
      <strong>Formwright</strong>
      <span class="guide-tag">Guide</span>
    </a>
    <nav aria-label="Site">
      <a href="https://joegaudet.com/formwright/demo/">Demo</a>
      <a href="https://github.com/joegaudet/formwright">GitHub</a>
    </nav>
  </header>

  <div class="guide-layout">
    <details class="guide-sidebar" open={{WIDE}}>
      <summary>Contents</summary>
      <PageNav>
        <:page as |x|>
          <x.Link>{{title x.page.name}}</x.Link>
        </:page>
        <:collection as |x|>
          {{title x.collection.name}}
        </:collection>
      </PageNav>
    </details>

    <main class="guide-main">
      {{outlet}}
    </main>
  </div>
</template>
