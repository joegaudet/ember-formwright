import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render, settled } from '@ember/test-helpers'
import { FormHarness, InputHarness, field } from '@ember-formwright/test-support'
import ProfileForm, { createModel } from 'docs-app/examples/submit-and-reset'

class ProfileHarness extends FormHarness {
  static formName = 'profile'
  @field(InputHarness) declare displayName: InputHarness
  @field(InputHarness) declare bio: InputHarness
}

module('Example | submit-and-reset', function (hooks) {
  setupRenderingTest(hooks)

  test('saves, then resets to the last saved values', async function (assert) {
    const model = createModel()
    await render(<template><ProfileForm @model={{model}} /></template>)
    const profile = new ProfileHarness()

    await profile.displayName.fillIn('Ada King')
    assert.true(profile.isDirty)
    assert.dom('.status').hasText('You have unsaved changes.')

    await profile.submit()
    assert.false(profile.isDirty)
    assert.dom('.status').includesText('Saved at')

    await profile.bio.fillIn('Something else')
    await profile.reset()
    assert.strictEqual(model.bio, 'Wrote the first program.')
    assert.strictEqual(model.displayName, 'Ada King', 'reset goes back to the saved value')
    await settled()
    await a11yAudit()
  })
})
