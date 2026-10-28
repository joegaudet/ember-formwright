import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, field } from '@ember-formwright/test-support'
import { DatePickerHarness } from '@ember-formwright/power-calendar/test-support'
import ReleaseForm, { createModel } from 'docs-app/examples/controls-date-picker-inline'

class ReleaseHarness extends FormHarness {
  static formName = 'release'
  @field(DatePickerHarness) declare shipsOn: DatePickerHarness
}

module('Example | controls-date-picker-inline', function (hooks) {
  setupRenderingTest(hooks)

  test('edits in a callout, within @min, @max and @disabledDates', async function (assert) {
    const model = createModel()
    await render(<template><ReleaseForm @model={{model}} /></template>)
    const release = new ReleaseHarness()

    assert.strictEqual(release.shipsOn.displayText, 'Wednesday, November 18, 2026')
    await release.shipsOn.edit()
    assert.true(await release.shipsOn.isDayDisabled('2026-11-21'), 'a Saturday')
    assert.true(await release.shipsOn.isDayDisabled('2026-12-21'), 'after @max')

    await release.shipsOn.select('2026-12-02')
    await release.shipsOn.commit()
    assert.deepEqual(model.shipsOn, new Date(2026, 11, 2), 'stores a Date')
    assert.strictEqual(release.shipsOn.displayText, 'Wednesday, December 2, 2026')
    await a11yAudit()
  })
})
