import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { render } from '@ember/test-helpers'
import { FormHarness, field } from '@ember-formwright/test-support'
import { PowerSelectHarness } from '@ember-formwright/power-select/test-support'
import TicketForm, { createModel } from 'docs-app/examples/controls-power-select'

class TicketHarness extends FormHarness {
  static formName = 'ticket'
  @field(PowerSelectHarness) declare owner: PowerSelectHarness
  @field(PowerSelectHarness) declare watchers: PowerSelectHarness
}

module('Example | controls-power-select', function (hooks) {
  setupRenderingTest(hooks)

  test('search, choose, and add to a multiple select', async function (assert) {
    const model = createModel()
    await render(<template><TicketForm @model={{model}} /></template>)
    const ticket = new TicketHarness()

    await ticket.owner.search('hop')
    await ticket.owner.select('Grace Hopper')
    assert.strictEqual(model.owner?.name, 'Grace Hopper')
    assert.deepEqual(ticket.owner.selected, ['Grace Hopper grace@example.com'])

    await ticket.owner.clear()
    assert.strictEqual(model.owner, null)

    assert.deepEqual(ticket.watchers.selected, ['Grace Hopper'])
    await ticket.watchers.select('Alan Turing')
    assert.deepEqual(model.watchers, [2, 3], 'stores the ids')
    await a11yAudit()
  })
})
