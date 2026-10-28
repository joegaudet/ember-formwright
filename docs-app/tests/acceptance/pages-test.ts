import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { visit, waitFor, find } from '@ember/test-helpers'

/** Every guide page, as `<folder>/<page>.md`; each must render without an error. */
const PAGES = [
  'getting-started/introduction.md',
  'getting-started/usage.md',
  'building-forms/forms.md',
  'building-forms/fields.md',
  'building-forms/validation.md',
  'building-forms/nested-forms.md',
  'controls/built-in-controls.md',
  'controls/custom-controls.md',
  'controls/power-select.md',
  'going-further/data-layers.md',
  'going-further/changesets.md',
  'going-further/theming.md',
  'going-further/testing.md',
  'reference/api.md',
]

module('Acceptance | guide pages', function (hooks) {
  setupApplicationTest(hooks)

  for (const page of PAGES) {
    test(`${page} renders`, async function (assert) {
      await visit(`/${page}`)
      await waitFor('.guide-prose h1, .guide-error', { timeout: 15000 })
      const error = find('.guide-error')?.textContent?.trim()
      assert.notOk(error, `page error: ${error}`)
      assert
        .dom('.guide-prose h1')
        .exists(
          (document.querySelector('.guide-main')?.textContent ?? '')
            .replace(/\s+/g, ' ')
            .slice(0, 600),
        )
      // Every section heading links to itself, so it can be shared.
      for (const heading of document.querySelectorAll('.guide-prose h2[id]')) {
        assert.dom(heading.querySelector('a.heading-anchor')).hasAttribute('href', `#${heading.id}`)
      }
      // Every <Example> on the page found its file.
      for (const example of document.querySelectorAll('[data-test-example]')) {
        assert
          .dom(example.querySelector('.example-preview'))
          .exists(example.getAttribute('data-test-example')!)
      }
    })
  }
})
