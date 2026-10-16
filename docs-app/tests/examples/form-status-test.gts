import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { click, render } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import ProfileForm, { createModel } from 'docs-app/examples/form-status'

class ProfileHarness extends FormHarness {
  static formName = 'profile'
  @field(InputHarness) declare name: InputHarness
}

module('Example | form-status', function (hooks) {
  setupRenderingTest(hooks)

  test('status walks clean, dirty, invalid, dirty, and back to clean', async function (assert) {
    const model = createModel()
    await render(<template><ProfileForm @model={{model}} /></template>)
    const profile = new ProfileHarness()

    assert.strictEqual(profile.status, 'clean')
    assert.dom('.status-badge').hasText('clean')

    await profile.name.fillIn('')
    assert.strictEqual(profile.status, 'dirty')

    await profile.submit()
    assert.strictEqual(profile.status, 'invalid')
    assert.deepEqual(profile.name.errors, ['Name is required'])

    await profile.name.fillIn('Grace')
    assert.strictEqual(profile.status, 'dirty')

    await profile.submit()
    assert.strictEqual(profile.status, 'clean', 'saved, so the new baseline')
    assert.dom('.status-badge').hasText('clean')
    await a11yAudit()
  })

  test('a failed save stays dirty', async function (assert) {
    const model = createModel()
    await render(<template><ProfileForm @model={{model}} /></template>)
    const profile = new ProfileHarness()

    await click('[data-test-fail-next]')
    await profile.name.fillIn('Grace')
    await profile.submit()
    assert.strictEqual(profile.status, 'dirty')
    assert
      .dom('.status-note')
      .hasText('The save failed. Your change is still here: retry or reset.')
  })
})
