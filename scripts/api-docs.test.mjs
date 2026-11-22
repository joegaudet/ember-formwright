// Builds the API reference (`pnpm docs:api`, after `pnpm build`) and checks what search engines
// and agents read from it: the pages, their meta, the source links, the sitemap and
// llms-full.txt.
import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'
import assert from 'node:assert/strict'

const root = new URL('../', import.meta.url)
const read = path => readFileSync(new URL(path, root), 'utf8')
const base = 'https://joegaudet.com/ember-formwright/api/'
const packages = [
  'changeset',
  'ember',
  'file-upload',
  'layouts',
  'maskito',
  'power-calendar',
  'power-select',
  'real-enums',
  'test-support',
  'tiptap',
  'warp-drive',
]

execFileSync('pnpm', ['docs:api'], { cwd: root, stdio: 'inherit' })

test('every package has a page', () => {
  const index = read('docs/api/index.html')
  for (const name of packages) assert.match(index, new RegExp(`@ember-formwright/${name}<`))
})

test('pages carry canonical, link-preview and JSON-LD meta', () => {
  const page = read('docs/api/index.html')
  assert.match(page, new RegExp(`<link rel="canonical" href="${base}"`))
  assert.match(
    page,
    /<meta property="og:image" content="https:\/\/joegaudet.com\/ember-formwright\/social-card.png"/,
  )
  assert.match(page, /<meta name="twitter:card" content="summary_large_image"/)
  const ld = JSON.parse(/<script type="application\/ld\+json">(.*?)<\/script>/s.exec(page)[1])
  assert.equal(ld['@type'], 'TechArticle')
  assert.equal(ld.url, base)
})

test('pages use the marketing site styles', () => {
  assert.match(read('docs/api/index.html'), /assets\/custom.css/)
  assert.match(read('docs/api/assets/custom.css'), /--brand-indigo/)
})

test('an Ember component links to its .gts source, not the emitted declarations', () => {
  const page = read('docs/api/interfaces/_ember-formwright_ember.FormState.html')
  assert.match(
    page,
    /href="https:\/\/github.com\/joegaudet\/ember-formwright\/blob\/[^/]+\/packages\/ember\/src\/components\/form.gts#L\d+"/,
  )
  assert.doesNotMatch(page, /\.d\.ts/)
})

test('a component lists its own members, not those Glimmer Component gives every one', () => {
  const page = read('docs/api/classes/_ember-formwright_ember.Form.html')
  assert.doesNotMatch(page, /willDestroy/)
})

test('the sitemap lists absolute API URLs', () => {
  assert.match(read('docs/api/sitemap.xml'), new RegExp(`<loc>${base}`))
})

test('llms-full.txt is llms.txt plus the API reference', () => {
  const full = read('docs/api/llms-full.txt')
  assert.ok(full.startsWith(read('docs/site/llms.txt')))
  assert.match(full, /## API reference/)
  assert.match(full, /registerControl/)
})

test('api.json is the TypeDoc model, for tools that read the API rather than the pages', () => {
  const model = JSON.parse(read('docs/api/api.json'))
  assert.equal(model.name, 'Formwright')
  assert.ok(model.children.some(child => child.name === '@ember-formwright/ember'))
})

test('an indented example in a comment renders as code, not as markup', async () => {
  const { fenceIndentedCode } = await import('./typedoc-site.mjs')
  assert.equal(
    fenceIndentedCode('Use it:\n\n  <f.Field @for="a" />\n    <x />\n\nAfter.'),
    'Use it:\n\n```handlebars\n<f.Field @for="a" />\n  <x />\n```\n\nAfter.',
  )
  assert.equal(fenceIndentedCode('A line\n  continued'), 'A line\n  continued')
  assert.match(read('docs/api/classes/_ember-formwright_maskito.index.Masked.html'), /<pre>/)
})
