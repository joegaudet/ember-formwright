// TypeDoc plugin for the API reference at joegaudet.com/ember-formwright/api/:
//
// - Each page gets the marketing site's link-preview card and JSON-LD, which TypeDoc has no
//   option for (it writes the canonical link and sitemap itself, from hostedBaseUrl).
// - Members a class inherits from a dependency are dropped: every component extends Glimmer's
//   `Component`, so each page would otherwise list `args`, `willDestroy` and the rest.
// - "Defined in" points at the source. The Ember packages are documented from the declarations
//   `pnpm build` emits (TypeDoc can't parse .gts), which git ignores, so TypeDoc has no link for
//   them; each location is mapped back through its `.d.ts.map` to the .gts or .ts it came from.
// - A component's page shows its signature, not its class members (see below).
// - A comment's indented examples are code. Formwright's comments show usage indented by two
//   spaces, which reads as code in an editor but as a paragraph (with its `<f.Field>` taken for
//   HTML) in Markdown, so each indented run becomes a fenced block.
import { existsSync, readFileSync } from 'node:fs'
import { basename, dirname, join, resolve } from 'node:path'
import { TraceMap, originalPositionFor } from '@jridgewell/trace-mapping'
import { Converter, JSX, ReflectionKind } from 'typedoc'

const SITE = 'https://joegaudet.com/ember-formwright/'
const CARD = `${SITE}social-card.png`

const fromDependency = reflection =>
  reflection.sources?.length > 0 &&
  reflection.sources.every(source => /\/node_modules\//.test(source.fullFileName))

const isComponent = reflection =>
  reflection.extendedTypes?.some(
    type =>
      type.type === 'reference' &&
      (type.package === '@glimmer/component' || (type.reflection && isComponent(type.reflection))),
  )

/** Markdown with each indented run of lines (at the start or after a blank line) fenced. */
export function fenceIndentedCode(markdown) {
  const lines = markdown.split('\n')
  const out = []
  let fence = false
  for (let index = 0; index < lines.length; index++) {
    const line = lines[index]
    if (!fence && /^ {2,}\S/.test(line) && (out.length === 0 || out.at(-1).trim() === '')) {
      const block = []
      while (index < lines.length && (/^ {2,}\S/.test(lines[index]) || !lines[index].trim()))
        block.push(lines[index++])
      index--
      while (block.length && !block.at(-1).trim()) block.pop()
      const indent = Math.min(...block.filter(l => l.trim()).map(l => /^ */.exec(l)[0].length))
      const code = block.map(l => l.slice(indent))
      const lang = code.some(l => /<[A-Za-z]|\{\{/.test(l)) ? 'handlebars' : 'typescript'
      out.push('```' + lang, ...code, '```', '')
      continue
    }
    if (/^\s*```/.test(line)) fence = !fence
    out.push(line)
  }
  return out.join('\n').replace(/\n+$/, '')
}

/** Fences a comment part list's indented code, unless it holds inline tags ({@link}). */
function fenceParts(parts) {
  if (!parts?.length || parts.some(part => part.kind !== 'text' && part.kind !== 'code')) return
  const text = fenceIndentedCode(parts.map(part => part.text).join(''))
  parts.splice(0, parts.length, { kind: 'text', text })
}

const maps = new Map()
function traceMap(file) {
  if (!maps.has(file)) {
    const path = `${file}.map`
    maps.set(file, existsSync(path) ? new TraceMap(readFileSync(path, 'utf8'), path) : null)
  }
  return maps.get(file)
}

/** A source in emitted declarations, moved to where its map says it was written. */
function toOriginal(source, reflection) {
  if (!source.fullFileName.endsWith('.d.ts') || /\/node_modules\//.test(source.fullFileName)) return
  const map = traceMap(source.fullFileName)
  if (!map) return
  const original = originalPositionFor(map, { line: source.line, column: source.character })
  if (original.source == null) return
  source.fullFileName = resolve(dirname(source.fullFileName), original.source)
  source.line = original.line
  source.character = original.column
  // ember-tsc's maps for .gts point at the file but not at the line (they map its transformed
  // code), so the line is found by the declaration's name instead.
  if (source.fullFileName.endsWith('.gts')) {
    source.line = lineOf(reflection, source.fullFileName)
    source.character = 0
  }
}

const sourceLines = new Map()
const escape = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

/** The line declaring `reflection` in `file`: a top-level name, or a member below its parent. */
function lineOf(reflection, file) {
  if (!sourceLines.has(file)) sourceLines.set(file, readFileSync(file, 'utf8').split('\n'))
  const lines = sourceLines.get(file)
  const named = reflection.variant === 'signature' ? reflection.parent : reflection
  let parent = named.parent
  while (parent && !parent.sources?.length) parent = parent.parent
  const parentLine = parent?.kindOf(ReflectionKind.SomeModule | ReflectionKind.Project)
    ? undefined
    : parent?.sources?.find(source => source.fullFileName === file)?.line
  const name = escape(named.name)
  const pattern = parentLine
    ? new RegExp(
        `^\\s*(?:(?:readonly|static|get|set|async|declare|override)\\s+)*['"]?${name}['"]?\\??\\s*[:(<=]`,
      )
    : new RegExp(
        `^(?:export\\s+)?(?:default\\s+)?(?:declare\\s+)?(?:abstract\\s+)?(?:interface|class|type|const|let|function|enum)\\s+${name}\\b`,
      )
  const index = lines.findIndex((line, i) => i >= (parentLine ?? 0) && pattern.test(line))
  return index === -1 ? (parentLine ?? 1) : index + 1
}

export function load(app) {
  // Ahead of TypeDoc's SourcePlugin (priority 0), which turns each location into a link.
  app.converter.on(
    Converter.EVENT_RESOLVE_BEGIN,
    context => {
      for (const reflection of Object.values(context.project.reflections))
        for (const source of reflection.sources ?? []) toOriginal(source, reflection)
    },
    100,
  )

  app.converter.on(Converter.EVENT_RESOLVE_BEGIN, context => {
    for (const reflection of context.project.getReflectionsByKind(ReflectionKind.ClassMember))
      if (reflection.inheritedFrom && fromDependency(reflection))
        context.project.removeReflection(reflection)
    // A component's API is its signature (Args, Blocks, Element): apps render it, never call
    // it. Its class members are what its own template reads, so its page leaves them out.
    for (const reflection of context.project.getReflectionsByKind(ReflectionKind.Class))
      if (isComponent(reflection))
        for (const member of [...(reflection.children ?? [])])
          context.project.removeReflection(member)
  })

  app.converter.on(Converter.EVENT_RESOLVE_BEGIN, context => {
    for (const reflection of Object.values(context.project.reflections)) {
      fenceParts(reflection.comment?.summary)
      for (const tag of reflection.comment?.blockTags ?? []) fenceParts(tag.content)
    }
  })

  // SourcePlugin names each file relative to the declarations; give it its source's name.
  app.converter.on(
    Converter.EVENT_RESOLVE_BEGIN,
    context => {
      for (const reflection of Object.values(context.project.reflections))
        for (const source of reflection.sources ?? [])
          if (source.fileName.endsWith('.d.ts') && !source.fullFileName.endsWith('.d.ts'))
            source.fileName = join(dirname(source.fileName), basename(source.fullFileName))
    },
    -100,
  )

  app.renderer.hooks.on('head.end', context => {
    const base = app.options.getValue('hostedBaseUrl')
    const url = new URL(context.page.url.replace(/(^|\/)index\.html$/, '$1'), base).href
    const title = context.page.model.isProject?.()
      ? 'Formwright API reference'
      : `${context.page.model.name} · Formwright API`
    const description = context.page.model.comment?.summary
      .map(part => part.text)
      .join('')
      .split('\n\n')[0]
    const ld = {
      '@context': 'https://schema.org',
      '@type': 'TechArticle',
      headline: title,
      url,
      isPartOf: { '@type': 'WebSite', name: 'Formwright', url: SITE },
      about: {
        '@type': 'SoftwareSourceCode',
        name: 'Formwright',
        codeRepository: 'https://github.com/joegaudet/ember-formwright',
        programmingLanguage: 'TypeScript',
      },
      author: { '@type': 'Person', name: 'Joe Gaudet', url: 'https://joegaudet.com/' },
    }
    return JSX.createElement(
      JSX.Fragment,
      null,
      JSX.createElement('meta', { property: 'og:type', content: 'article' }),
      JSX.createElement('meta', { property: 'og:site_name', content: 'Formwright' }),
      JSX.createElement('meta', { property: 'og:title', content: title }),
      description &&
        JSX.createElement('meta', { property: 'og:description', content: description }),
      JSX.createElement('meta', { property: 'og:url', content: url }),
      JSX.createElement('meta', { property: 'og:image', content: CARD }),
      JSX.createElement('meta', { property: 'og:image:width', content: '1200' }),
      JSX.createElement('meta', { property: 'og:image:height', content: '630' }),
      JSX.createElement('meta', { name: 'twitter:card', content: 'summary_large_image' }),
      JSX.createElement('link', {
        rel: 'alternate',
        type: 'text/plain',
        href: `${SITE}llms.txt`,
        title: 'llms.txt',
      }),
      JSX.createElement(
        'script',
        { type: 'application/ld+json' },
        JSX.createElement(JSX.Raw, { html: JSON.stringify(ld).replaceAll('<', '\\u003c') }),
      ),
    )
  })
}
