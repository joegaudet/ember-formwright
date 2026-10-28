import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, field } from '@ember-formwright/test-support'
import { PowerSelectHarness } from '@ember-formwright/power-select/test-support'
import ProjectForm, { createModel } from 'docs-app/examples/controls-power-select-async'

class ProjectHarness extends FormHarness {
  static formName = 'project'
  @field(PowerSelectHarness) declare lead: PowerSelectHarness
}

module('Example | controls-power-select-async', function (hooks) {
  setupRenderingTest(hooks)

  test('searches as you type, and commits from the callout', async function (assert) {
    const model = createModel()
    await render(<template><ProjectForm @model={{model}} /></template>)
    const project = new ProjectHarness()

    assert.strictEqual(project.lead.displayText, 'Ada Lovelace')
    await project.lead.edit()
    await project.lead.search('marg')
    assert.deepEqual(await project.lead.options(), ['Margaret Hamilton'])
    await project.lead.select('Margaret Hamilton')
    await project.lead.commit()

    assert.strictEqual(model.lead?.name, 'Margaret Hamilton')
    assert.strictEqual(project.lead.displayText, 'Margaret Hamilton')
    await a11yAudit()
  })
})
