// Checks on the hand-written site in docs/site: run with `node --test scripts/*.test.mjs`.
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { describe, it } from 'node:test'

const html = readFileSync(new URL('../docs/site/index.html', import.meta.url), 'utf8')
const sections = [...html.matchAll(/<section id="([^"]+)">([\s\S]*?)<\/section>/g)]

describe('docs/site sections', () => {
  it('has sections', () => assert.ok(sections.length > 0))

  for (const [, id, body] of sections) {
    it(`#${id}: its heading links to itself, so it can be shared`, () => {
      const heading = body.match(/<h2[^>]*>([\s\S]*?)<\/h2>/)?.[1] ?? ''
      assert.match(heading, new RegExp(`<a[^>]*href="#${id}"`))
    })
  }
})
