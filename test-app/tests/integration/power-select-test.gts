import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, settled, triggerKeyEvent, waitUntil } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { FormHarness, field } from '@ember-formwright/test-support'
import { registerPowerSelectControls } from '@ember-formwright/power-select'
import { PowerSelectHarness } from '@ember-formwright/power-select/test-support'

registerPowerSelectControls()

interface User {
  id: number
  name: string
  email: string
}

const USERS: User[] = [
  { id: 1, name: 'Ada Lovelace', email: 'ada@example.com' },
  { id: 2, name: 'Grace Hopper', email: 'grace@example.com' },
  { id: 3, name: 'Alan Turing', email: 'alan@example.com' },
]

class Task {
  @tracked owner: User | number | null = null
  @tracked watchers: (User | number)[] = []
}

class TaskForm extends FormHarness {
  @field(PowerSelectHarness) declare owner: PowerSelectHarness
  @field(PowerSelectHarness) declare watchers: PowerSelectHarness
}

const searchUsers = async (term: string) => {
  await Promise.resolve()
  return USERS.filter(u => u.name.toLowerCase().includes(term.toLowerCase()))
}
const userName = (value: unknown) => (value as User | null)?.name ?? ''

module('Integration | power-select', function (hooks) {
  setupRenderingTest(hooks)

  let ui: TaskForm
  hooks.beforeEach(function () {
    ui = new TaskForm()
  })

  test('power-select stores the chosen option, with the field wired to its trigger', async function (assert) {
    const task = new Task()

    await render(
      <template>
        <Form @model={{task}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @hint="Who does it"
            @placeholder="Pick someone"
            @required={{true}}
            @options={{USERS}}
            @optionLabel="name"
          />
        </Form>
      </template>,
    )

    const trigger = ui.owner.trigger
    assert.dom('[data-test-fw-field="owner"] label').hasAttribute('for', trigger.id)
    assert.dom(trigger).hasClass('ember-power-select-trigger')
    assert.dom(trigger).hasAttribute('aria-label', 'Owner')
    assert.dom(trigger).hasAttribute('aria-required', 'true')
    assert.dom(trigger).hasAttribute('aria-describedby', `${trigger.id}-hint`)
    assert
      .dom('[data-test-fw-field="owner"] [data-test-fw-control]')
      .hasAttribute('data-test-fw-control', 'power-select')
      .hasAttribute('data-fw-name', 'form.owner')
    assert.dom(trigger).hasText('Pick someone')

    assert.deepEqual(await ui.owner.options(), ['Ada Lovelace', 'Grace Hopper', 'Alan Turing'])
    await ui.owner.select('Grace Hopper')
    assert.strictEqual(task.owner, USERS[1])
    assert.deepEqual(ui.owner.selected, ['Grace Hopper'])
    assert.true(ui.owner.isDirty)
  })

  test('@storeKey stores the key and shows the stored option on first render', async function (assert) {
    const task = new Task()
    task.owner = 3

    await render(
      <template>
        <Form @model={{task}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @options={{USERS}}
            @optionLabel="name"
            @storeKey={{true}}
          />
        </Form>
      </template>,
    )

    assert.deepEqual(ui.owner.selected, ['Alan Turing'])
    await ui.owner.select('Ada')
    assert.strictEqual(task.owner, 1)
  })

  test('the block renders each option, and extra args reach power-select', async function (assert) {
    const task = new Task()
    task.owner = USERS[0]!

    await render(
      <template>
        <Form @model={{task}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @options={{USERS}}
            as |field|
          >
            <field.Control @searchEnabled={{true}} @allowClear={{true}} as |user|>
              <span data-test-user>{{userName user}}</span>
            </field.Control>
          </f.Field>
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-field="owner"] [data-test-user]').hasText('Ada Lovelace')
    await ui.owner.search('tur')
    assert.deepEqual(await ui.owner.options(), ['Alan Turing'])
    await ui.owner.select('Alan Turing')
    assert.strictEqual(task.owner, USERS[2])

    await ui.owner.clear()
    assert.strictEqual(task.owner, null)
    assert.deepEqual(ui.owner.selected, [])
  })

  test('power-select-multiple stores an array, of options or keys', async function (assert) {
    const task = new Task()
    task.watchers = [2]

    await render(
      <template>
        <Form @model={{task}} as |f|>
          <f.Field
            @for="watchers"
            @control="power-select-multiple"
            @label="Watchers"
            @options={{USERS}}
            @optionLabel="name"
            @storeKey={{true}}
          />
        </Form>
      </template>,
    )

    assert.deepEqual(ui.watchers.selected, ['Grace Hopper'])
    await ui.watchers.select('Ada Lovelace')
    assert.deepEqual(task.watchers, [2, 1])
    await ui.watchers.remove('Grace Hopper')
    assert.deepEqual(task.watchers, [1])
    await ui.watchers.clear()
    assert.deepEqual(task.watchers, [])
  })

  test('disabled and readonly disable the trigger', async function (assert) {
    const task = new Task()

    await render(
      <template>
        <Form @model={{task}} @readonly={{true}} as |f|>
          <f.Field @for="owner" @control="power-select" @label="Owner" @options={{USERS}} />
        </Form>
        <Form @model={{task}} @disabled={{true}} @name="other" as |f|>
          <f.Field @for="watchers" @control="power-select-multiple" @label="W" @options={{USERS}} />
        </Form>
      </template>,
    )

    assert.dom(ui.owner.trigger).hasAttribute('aria-disabled', 'true')
    assert
      .dom('[data-test-fw-form="other"] .ember-power-select-trigger')
      .hasAttribute('aria-disabled', 'true')
  })

  test('async search: options come from @search, and @format shows the value inline', async function (assert) {
    const task = new Task()
    task.owner = USERS[0]!

    await render(
      <template>
        <Form @model={{task}} @inline={{true}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @format={{userName}}
            as |field|
          >
            <field.Control @search={{searchUsers}} @searchEnabled={{true}} as |user|>
              {{userName user}}
            </field.Control>
          </f.Field>
        </Form>
      </template>,
    )

    assert.strictEqual(ui.owner.displayText, 'Ada Lovelace')
    await ui.owner.edit()
    assert.dom(ui.owner.trigger).isFocused('editing focuses the trigger')
    await ui.owner.search('grace')
    assert.deepEqual(await ui.owner.options(), ['Grace Hopper'])
    await ui.owner.select('Grace Hopper')
    assert.strictEqual(task.owner, USERS[0], 'inline mode waits for the commit')
    await ui.owner.commit()
    assert.strictEqual(task.owner, USERS[1])
    assert.strictEqual(ui.owner.displayText, 'Grace Hopper')
  })

  test('inline mode without @format shows an option object by its label, not [object Object]', async function (assert) {
    const task = new Task()
    task.owner = USERS[1]!

    await render(
      <template>
        <Form @model={{task}} @inline={{true}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @optionLabel="name"
            as |field|
          >
            <field.Control @search={{searchUsers}} @searchEnabled={{true}} />
          </f.Field>
        </Form>
      </template>,
    )

    assert.strictEqual(ui.owner.displayText, 'Grace Hopper')
  })

  test('@storeKey with async search: @selectedOption maps the stored key to its option', async function (assert) {
    const task = new Task()
    task.owner = 1
    const current = USERS[0]

    await render(
      <template>
        <Form @model={{task}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @optionLabel="name"
            @storeKey={{true}}
            as |field|
          >
            <field.Control
              @search={{searchUsers}}
              @searchEnabled={{true}}
              @selectedOption={{current}}
            />
          </f.Field>
        </Form>
      </template>,
    )

    assert.deepEqual(ui.owner.selected, ['Ada Lovelace'])
    await ui.owner.search('alan')
    await ui.owner.select('Alan Turing')
    assert.strictEqual(task.owner, 3)
    assert.deepEqual(ui.owner.selected, ['Alan Turing'], 'a chosen option is remembered')
  })

  test('in a callout, the dropdown renders inside the popover and choosing keeps it open', async function (assert) {
    const task = new Task()

    await render(
      <template>
        <Form @model={{task}} @inline={{true}} @callout={{true}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @options={{USERS}}
            @optionLabel="name"
          />
        </Form>
      </template>,
    )

    await ui.owner.edit()
    const popover = ui.owner.element.querySelector<HTMLElement>('[popover]')!
    assert.true(popover.matches(':popover-open'))
    assert.dom(ui.owner.trigger).isFocused()

    await click(ui.owner.trigger)
    assert.dom('.ember-power-select-dropdown', popover).exists('the dropdown is inside the popover')

    await ui.owner.select('Alan Turing')
    assert.true(popover.matches(':popover-open'), 'choosing an option does not close the callout')
    assert.strictEqual(task.owner, null, 'not committed yet')
    await ui.owner.commit()
    assert.strictEqual(task.owner, USERS[2])
  })

  test('keyboard with @requireConfirm: Enter chooses without committing, Escape closes the dropdown first', async function (assert) {
    const task = new Task()

    await render(
      <template>
        <Form @model={{task}} @requireConfirm={{true}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @options={{USERS}}
            @optionLabel="name"
            as |field|
          >
            <field.Control @renderInPlace={{true}} />
          </f.Field>
        </Form>
      </template>,
    )

    const trigger = ui.owner.trigger
    trigger.focus()
    await triggerKeyEvent(trigger, 'keydown', 'ArrowDown')
    assert.true(ui.owner.isOpen, 'ArrowDown opens the dropdown')
    await triggerKeyEvent(trigger, 'keydown', 'ArrowDown')
    await triggerKeyEvent(trigger, 'keydown', 'Enter')
    assert.deepEqual(ui.owner.selected, ['Grace Hopper'], 'Enter chooses the highlighted option')
    assert.strictEqual(task.owner, null, 'Enter does not commit the field')
    assert.dom('[data-test-fw-commit]').exists('the choice waits for confirm')

    await triggerKeyEvent(trigger, 'keydown', 'ArrowDown')
    assert.true(ui.owner.isOpen)
    await triggerKeyEvent(trigger, 'keydown', 'Escape')
    assert.false(ui.owner.isOpen, 'the first Escape closes the dropdown')
    assert.deepEqual(ui.owner.selected, ['Grace Hopper'], '... and keeps the pending choice')

    await triggerKeyEvent(trigger, 'keydown', 'Escape')
    assert.deepEqual(ui.owner.selected, [], 'the second Escape cancels the field')
    assert.strictEqual(task.owner, null)

    await triggerKeyEvent(trigger, 'keydown', 'ArrowDown')
    await triggerKeyEvent(trigger, 'keydown', 'Enter')
    await triggerKeyEvent(trigger, 'keydown', 'Enter')
    assert.strictEqual(task.owner, USERS[0], 'Enter on the closed trigger commits')
  })

  test('keyboard in inline mode: Enter on an option keeps editing', async function (assert) {
    const task = new Task()

    await render(
      <template>
        <Form @model={{task}} @inline={{true}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @options={{USERS}}
            @optionLabel="name"
            as |field|
          >
            <field.Control @renderInPlace={{true}} />
          </f.Field>
        </Form>
      </template>,
    )

    await ui.owner.edit()
    const trigger = ui.owner.trigger
    await triggerKeyEvent(trigger, 'keydown', 'ArrowDown')
    await triggerKeyEvent(trigger, 'keydown', 'Enter')
    assert.strictEqual(task.owner, null, 'not committed')
    assert.dom(ui.owner.trigger).exists('still editing')
    await triggerKeyEvent(trigger, 'keydown', 'Enter')
    assert.strictEqual(task.owner, USERS[0], 'Enter on the closed trigger commits')
    assert.strictEqual(ui.owner.displayText, 'Ada Lovelace')
  })

  test('both controls pass axe, valid and invalid', async function (assert) {
    const task = new Task()
    const validator = (t: Task): ErrorMap =>
      t.owner ? {} : { owner: ['Pick an owner'], watchers: ['Add a watcher'] }

    await render(
      <template>
        <Form @model={{task}} @validator={{validator}} as |f|>
          <f.Field
            @for="owner"
            @control="power-select"
            @label="Owner"
            @hint="Who does it"
            @options={{USERS}}
            @optionLabel="name"
          />
          <f.Field
            @for="watchers"
            @control="power-select-multiple"
            @label="Watchers"
            @options={{USERS}}
            @optionLabel="name"
          />
          <f.Submit />
        </Form>
      </template>,
    )

    await a11yAudit()
    await ui.submit()
    await waitUntil(() => ui.owner.isInvalid)
    assert.dom(ui.owner.trigger).hasAttribute('aria-invalid', 'true')
    assert.dom(ui.watchers.trigger).hasAttribute('aria-invalid', 'true')
    assert.deepEqual(ui.owner.errors, ['Pick an owner'])
    await a11yAudit()

    await ui.watchers.select('Ada')
    await a11yAudit()
    await settled()
    assert.ok(true, 'axe passes with both open states')
  })
})
