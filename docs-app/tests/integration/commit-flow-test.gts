import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { click, render } from '@ember/test-helpers'
import { CommitFlow } from 'docs-app/components/commit-flow'

const lane = (name: string) => `[data-test-flow-lane="${name}"] [data-test-flow-value]`
const caption = '[data-test-flow-caption]'
const status = '[data-test-flow-status]'
const current = '[data-test-flow-state][aria-current="step"]'
const next = () => click('[data-test-flow-next]')
const choose = async (...settings: string[]) => {
  for (const setting of settings) await click(`[${setting}]`)
}

module('Integration | CommitFlow', function (hooks) {
  setupRenderingTest(hooks)

  test('starts on the default data layer, in a form, clean', async function (assert) {
    await render(<template><CommitFlow /></template>)

    assert.dom('[data-test-flow-layer="default"]').hasAttribute('aria-pressed', 'true')
    assert.dom('[data-test-flow-mode="form"]').hasAttribute('aria-pressed', 'true')
    assert.dom(current).hasText('Clean')
    assert.dom(status).includesText("status: 'clean'")
    assert.dom('[data-test-flow-lane="draft"]').doesNotExist('no draft outside inline mode')
    assert.dom('[data-test-flow-lane="pending"]').includesText('Model')
    assert.dom(lane('pending')).hasText('Ada', 'by default the model itself holds the value')
    assert.dom('[data-test-flow-lane="saved"]').includesText('Baseline')
    assert.dom('[data-test-flow-back]').isDisabled()
    await a11yAudit()
  })

  test('default commit: dirty, submitting, then clean on a new baseline', async function (assert) {
    await render(<template><CommitFlow /></template>)

    await next()
    assert.dom(current).hasText('Dirty')
    assert.dom(status).includesText('isDirty: true')
    assert.dom(lane('pending')).hasText('Grace')
    assert.dom(caption).includesText("set(model, 'name', 'Grace')")

    await next()
    assert.dom(current).hasText('Submitting')
    assert.dom('[data-test-flow-ui-submit]').hasClass('is-pressed').hasText('Saving…')
    assert.dom(caption).includesText('model.save()')

    await next()
    assert.dom(current).hasText('Clean')
    assert.dom(lane('saved')).hasText('Grace')
    assert.dom(caption).includesText('new baseline')
    assert.dom('[data-test-flow-next]').isDisabled('the last step')
  })

  test('default roll back: Reset writes the baseline back', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await choose('data-test-flow-scenario="rollback"')

    await next()
    await next()
    assert.dom(current).hasText('Clean')
    assert.dom(caption).includesText('baseline')
    assert.dom(lane('field')).hasText('Ada')
    assert.dom(lane('pending')).hasText('Ada', 'the baseline is back on the model')
  })

  test('WarpDrive invalid submit: invalid, fixed, then saved', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await choose('data-test-flow-layer="warp-drive"', 'data-test-flow-scenario="invalid"')

    await next()
    assert.dom(current).hasText('Dirty')
    assert.dom(caption).includesText("record.name = ''")

    await next()
    assert.dom(current).hasText('Invalid')
    assert.dom(status).includesText('isValid: false')
    assert.dom('[data-test-flow-ui-error]').hasText('Name is required')
    assert.dom(lane('saved')).hasText('Ada', 'nothing reached the server')

    await next()
    assert.dom(current).hasText('Dirty', 'fixing the error leaves it dirty')
    assert.dom('[data-test-flow-ui-error]').doesNotExist()
    assert.dom(caption).includesText('re-validates')

    await next()
    assert.dom(current).hasText('Submitting')
    assert.dom(caption).includesText('record.save()')

    await next()
    assert.dom(current).hasText('Clean')
    assert.dom(lane('saved')).hasText('Grace')
  })

  test('a failed save, with each data layer', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await choose('data-test-flow-layer="changeset"', 'data-test-flow-scenario="failed"')

    await next()
    await next()
    await next()
    assert.dom(current).hasText('Dirty', 'a failed save stays dirty')
    assert.dom(lane('pending')).hasText('Grace', 'the edit stays in the changeset')
    assert.dom(lane('saved')).hasText('Ada', 'the model is put back')
    assert.dom(caption).includesText('puts Ada back on the model')

    await choose('data-test-flow-layer="warp-drive"')
    await next()
    await next()
    await next()
    assert
      .dom('[data-test-flow-ui-error]')
      .hasText('Name is taken', 'server errors show on the field')
    assert.dom(caption).includesText('record.errors')

    await choose('data-test-flow-layer="default"')
    await next()
    await next()
    await next()
    assert.dom(lane('pending')).hasText('Grace', 'the model still holds the edit')
    assert.dom(lane('saved')).hasText('Ada', 'the baseline has not moved')
  })

  test('inline with ember-changeset: a draft is still clean, commit makes it dirty', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await choose('data-test-flow-mode="inline"', 'data-test-flow-layer="changeset"')
    assert.dom('[data-test-flow-ui-display]').hasText('Ada')
    assert.dom('[data-test-flow-ui-input]').doesNotExist('not editing yet')

    await next()
    assert.dom(current).hasText('Clean', 'nothing has reached the changeset')
    assert.dom(lane('draft')).hasText('Grace')
    assert.dom(lane('pending')).doesNotExist()
    assert.dom('[data-test-flow-ui-input]').hasText('Grace')
    assert.dom('[data-test-flow-ui-commit]').exists()

    await next()
    assert.dom(current).hasText('Dirty')
    assert.dom(lane('pending')).hasText('Grace')
    assert.dom(caption).includesText("changeset.set('name', 'Grace')")
    assert.dom('[data-test-flow-ui-pressed]').hasText('✓')

    await next()
    assert.dom(current).hasText('Submitting')
    assert.dom(caption).includesText('changeset.save()')

    await next()
    assert.dom(current).hasText('Clean')
    assert.dom(lane('saved')).hasText('Grace')
  })

  test('inline roll back: Cancel drops a draft, Reset rolls back a commit', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await choose('data-test-flow-mode="inline"', 'data-test-flow-layer="changeset"')
    await choose('data-test-flow-scenario="rollback"')

    await next()
    await next()
    assert.dom(current).hasText('Clean')
    assert.dom('[data-test-flow-ui-pressed]').hasText('✕')
    assert.dom(lane('draft')).doesNotExist()

    await next()
    await next()
    assert.dom(current).hasText('Dirty')

    await next()
    assert.dom(current).hasText('Clean')
    assert.dom(caption).includesText('changeset.rollback()')
    assert.dom(lane('pending')).doesNotExist()
    await a11yAudit()
  })

  test('Back steps backwards, and changing a setting starts over', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await next()
    await click('[data-test-flow-back]')
    assert.dom(current).hasText('Clean')

    await next()
    await choose('data-test-flow-layer="warp-drive"')
    assert.dom(current).hasText('Clean')
    assert.dom(lane('field')).hasText('Ada')
  })
})
