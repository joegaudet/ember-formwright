import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import NewsletterForm, { createModel } from 'docs-app/examples/theming-custom'

class NewsletterHarness extends FormHarness {
  static formName = 'newsletter'
  @field(InputHarness) declare email: InputHarness
}

module('Example | theming-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('custom properties restyle everything inside', async function (assert) {
    const model = createModel()
    await render(<template><NewsletterForm @model={{model}} /></template>)
    const newsletter = new NewsletterHarness()

    const accent = getComputedStyle(newsletter.element).getPropertyValue('--fw-accent').trim()
    assert.strictEqual(accent, '#c2410c')
    await newsletter.email.fillIn('ada@example.com')
    assert.strictEqual(model.email, 'ada@example.com')
    await a11yAudit()
  })
})
