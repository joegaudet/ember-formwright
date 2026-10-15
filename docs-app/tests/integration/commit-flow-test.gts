import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { click, render } from '@ember/test-helpers'
import { CommitFlow } from 'docs-app/components/commit-flow'

const lane = (name: string) => `[data-test-flow-lane="${name}"] [data-test-flow-value]`
const caption = '[data-test-flow-caption]'

module('Integration | CommitFlow', function (hooks) {
  setupRenderingTest(hooks)

  test('form mode with WarpDrive: each change writes to the record, submit saves it', async function (assert) {
    await render(<template><CommitFlow /></template>)

    assert.dom('[data-test-flow-lane="draft"]').doesNotExist('no draft outside inline mode')
    assert.dom(lane('field')).hasText('Ada')
    assert.dom(lane('saved')).hasText('Ada')

    await click('[data-test-flow-next]')
    assert.dom(lane('field')).hasText('Grace')
    assert.dom(lane('pending')).hasText('Grace')
    assert.dom(caption).includesText("record.name = 'Grace'")

    await click('[data-test-flow-next]')
    assert.dom(lane('pending')).doesNotExist()
    assert.dom(lane('saved')).hasText('Grace')
    assert.dom(caption).includesText('record.save()')
    assert.dom('[data-test-flow-next]').isDisabled('the last step')
    await a11yAudit()
  })

  test('inline mode with ember-changeset: draft, commit, then save', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await click('[data-test-flow-mode="inline"]')
    await click('[data-test-flow-layer="changeset"]')

    await click('[data-test-flow-next]')
    assert.dom(lane('draft')).hasText('Grace')
    assert.dom(lane('pending')).doesNotExist('nothing is written before commit')

    await click('[data-test-flow-next]')
    assert.dom(lane('draft')).doesNotExist()
    assert.dom(lane('pending')).hasText('Grace')
    assert.dom(caption).includesText("changeset.set('name', 'Grace')")
    assert.dom(lane('saved')).hasText('Ada', 'the model has not changed yet')

    await click('[data-test-flow-next]')
    assert.dom(lane('saved')).hasText('Grace')
    assert.dom(caption).includesText('changeset.save()')
  })

  test('rolling back: reset in form mode, cancel in inline mode', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await click('[data-test-flow-layer="changeset"]')
    await click('[data-test-flow-scenario="rollback"]')

    await click('[data-test-flow-next]')
    await click('[data-test-flow-next]')
    assert.dom(caption).includesText('changeset.rollback()')
    assert.dom(lane('field')).hasText('Ada')
    assert.dom(lane('pending')).doesNotExist()
    assert.dom(lane('saved')).hasText('Ada')

    await click('[data-test-flow-mode="inline"]')
    assert.dom(lane('field')).hasText('Ada', 'switching mode starts over')
    await click('[data-test-flow-next]')
    await click('[data-test-flow-next]')
    assert.dom(caption).includesText('Cancel')
    assert.dom(lane('draft')).doesNotExist()
    assert.dom(lane('pending')).doesNotExist()
  })

  test('form mode draws the input and presses Submit, then Reset', async function (assert) {
    await render(<template><CommitFlow /></template>)
    assert.dom('[data-test-flow-ui-input]').hasText('Ada')
    assert.dom('[data-test-flow-ui-commit]').doesNotExist('no ✓ outside inline mode')

    await click('[data-test-flow-next]')
    assert.dom('[data-test-flow-ui-input]').hasText('Grace')
    assert.dom('.is-pressed').doesNotExist()

    await click('[data-test-flow-next]')
    assert.dom('[data-test-flow-ui-submit]').hasClass('is-pressed')

    await click('[data-test-flow-scenario="rollback"]')
    await click('[data-test-flow-next]')
    await click('[data-test-flow-next]')
    assert.dom('[data-test-flow-ui-reset]').hasClass('is-pressed')
    assert.dom('[data-test-flow-ui-input]').hasText('Ada')
  })

  test('inline mode draws the value, the editor, and its ✓ and ✕', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await click('[data-test-flow-mode="inline"]')
    assert.dom('[data-test-flow-ui-display]').hasText('Ada')
    assert.dom('[data-test-flow-ui-input]').doesNotExist('not editing yet')

    await click('[data-test-flow-next]')
    assert.dom('[data-test-flow-ui-input]').hasText('Grace')
    assert.dom('[data-test-flow-ui-commit]').exists()
    assert.dom('[data-test-flow-ui-cancel]').exists()

    await click('[data-test-flow-next]')
    assert.dom('[data-test-flow-ui-display]').hasText('Grace', 'commit closes the editor')
    assert.dom('[data-test-flow-ui-pressed]').hasText('✓')

    await click('[data-test-flow-scenario="rollback"]')
    await click('[data-test-flow-next]')
    await click('[data-test-flow-next]')
    assert.dom('[data-test-flow-ui-display]').hasText('Ada')
    assert.dom('[data-test-flow-ui-pressed]').hasText('✕')
    await a11yAudit()
  })

  test('native rollback: the model changes, Formwright restores its baseline', async function (assert) {
    await render(<template><CommitFlow /></template>)
    await click('[data-test-flow-layer="native"]')
    assert.dom('[data-test-flow-lane="pending"]').includesText('Model')
    assert.dom('[data-test-flow-lane="saved"]').includesText('Baseline')
    assert.dom(lane('pending')).hasText('Ada', 'the model always holds a value')

    await click('[data-test-flow-next]')
    assert.dom(lane('pending')).hasText('Grace')
    assert.dom(caption).includesText("set(model, 'name', 'Grace')")

    await click('[data-test-flow-scenario="rollback"]')
    await click('[data-test-flow-next]')
    await click('[data-test-flow-next]')
    assert.dom(caption).includesText('baseline')
    assert.dom(lane('field')).hasText('Ada')
    assert.dom(lane('pending')).hasText('Ada', 'the baseline is back on the model')
    assert.dom(lane('saved')).hasText('Ada')

    await click('[data-test-flow-scenario="commit"]')
    await click('[data-test-flow-next]')
    await click('[data-test-flow-next]')
    assert.dom(caption).includesText('new baseline')
    assert.dom(lane('saved')).hasText('Grace')
  })

  test('Back steps backwards', async function (assert) {
    await render(<template><CommitFlow /></template>)
    assert.dom('[data-test-flow-back]').isDisabled()
    await click('[data-test-flow-next]')
    await click('[data-test-flow-back]')
    assert.dom(lane('field')).hasText('Ada')
  })
})
