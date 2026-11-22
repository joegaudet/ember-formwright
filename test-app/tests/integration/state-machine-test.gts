import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, settled } from '@ember/test-helpers'
import type { TOC } from '@ember/component/template-only'
import { tracked } from '@glimmer/tracking'
import {
  Form,
  FormStatus,
  FieldStatus,
  type ErrorMap,
  type FieldLayoutSignature,
  type FormState,
} from '@ember-formwright/ember'
import { TestForm } from 'test-app/tests/helpers/test-form'

class User {
  @tracked name = 'Ada'
}

/** Shows the field's status, and which of its `is` predicates hold. */
const WithStatus: TOC<FieldLayoutSignature> = <template>
  <span data-test-field-status>{{@field.status.value}}</span>
  <span data-test-field-is>
    {{~if @field.status.isIdle "idle"~}}
    {{~if @field.status.isEditing "editing"~}}
    {{~if @field.status.isPending "pending"~}}
  </span>
  <span data-test-field-is-not>{{if @field.status.isNotIdle "busy"}}</span>
  <@parts.Label />
  <@parts.Control as |control|>{{yield control}}</@parts.Control>
</template>

module('Integration | state machines', function (hooks) {
  setupRenderingTest(hooks)

  let ui: TestForm
  hooks.beforeEach(function () {
    ui = new TestForm()
  })

  test('FormStatus is a real enum with is / isNot predicates', function (assert) {
    assert.deepEqual(
      FormStatus.values.map(s => s.value),
      ['clean', 'dirty', 'invalid', 'submitting'],
    )
    assert.true(FormStatus.Dirty.isDirty)
    assert.false(FormStatus.Dirty.isClean)
    assert.true(FormStatus.Dirty.isNotClean)
    assert.false(FormStatus.Submitting.isNotSubmitting)
    assert.strictEqual(String(FormStatus.Invalid), 'invalid', 'renders as its value')
  })

  test('f.state.status is a FormStatus member the template can ask is / isNot', async function (assert) {
    const user = new User()
    let state!: FormState<User>
    const keep = (s: FormState<User>) => void (state = s)
    let finish!: () => void
    const onSubmit = () => new Promise<void>(r => (finish = r))
    const validator = (u: User): ErrorMap<User> => (u.name ? {} : { name: ['Name is required'] })

    await render(
      <template>
        <Form @model={{user}} @validator={{validator}} @onSubmit={{onSubmit}} as |f|>
          {{keep f.state}}
          <f.Field @for="name" @label="Name" />
          <span data-test-is>
            {{~if f.state.status.isClean "clean"~}}
            {{~if f.state.status.isDirty "dirty"~}}
            {{~if f.state.status.isInvalid "invalid"~}}
            {{~if f.state.status.isSubmitting "submitting"~}}
          </span>
          <span data-test-is-not>{{if f.state.status.isNotClean "unsaved"}}</span>
          <f.Submit />
        </Form>
      </template>,
    )

    assert.strictEqual(state.status, FormStatus.Clean)
    assert.dom('[data-test-is]').hasText('clean')
    assert.dom('[data-test-is-not]').hasText('')

    await ui.name.fillIn('')
    assert.strictEqual(state.status, FormStatus.Dirty)
    assert.dom('[data-test-is-not]').hasText('unsaved')

    await ui.submit()
    assert.strictEqual(state.status, FormStatus.Invalid)
    assert.dom('[data-test-is]').hasText('invalid')

    await ui.name.fillIn('Grace')
    assert.strictEqual(state.status, FormStatus.Dirty, 'fixing the error leaves it dirty')

    void click('[data-test-fw-submit]')
    await new Promise(r => setTimeout(r, 10))
    assert.strictEqual(state.status, FormStatus.Submitting)
    assert.dom('[data-test-is]').hasText('submitting')
    assert.dom('form').hasAttribute('data-status', 'submitting', 'data-status keeps the value')
    finish()
    await settled()
    assert.strictEqual(state.status, FormStatus.Clean)
  })

  test('a failed submit keeps revalidating until saved, even after a failed save', async function (assert) {
    const user = new User()
    let fail = true
    const onSubmit = () => (fail ? Promise.reject(new Error('422')) : Promise.resolve())
    const failedSubmit = () => {}
    const validator = (u: User): ErrorMap<User> => (u.name ? {} : { name: ['Name is required'] })

    await render(
      <template>
        <Form
          @model={{user}}
          @validator={{validator}}
          @onSubmit={{onSubmit}}
          @failedSubmit={{failedSubmit}}
          as |f|
        >
          <f.Field @for="name" @label="Name" />
          <span data-test-status>{{f.state.status.value}}</span>
        </Form>
      </template>,
    )

    await ui.name.fillIn('')
    await ui.submit()
    assert.dom('[data-test-status]').hasText('invalid')
    await ui.name.fillIn('Grace')
    await ui.submit()
    assert.dom('[data-test-status]').hasText('dirty', 'the save failed')

    await ui.name.fillIn('')
    assert.dom('[data-test-status]').hasText('invalid', 'still revalidating on change')

    fail = false
    await ui.name.fillIn('Hopper')
    await ui.submit()
    await ui.name.fillIn('')
    assert.dom('[data-test-status]').hasText('dirty', 'saved: no longer revalidating')
  })

  test('a field with requireConfirm goes idle → pending → idle', async function (assert) {
    const user = new User()

    await render(
      <template>
        <Form @model={{user}} @requireConfirm={{true}} @layout={{WithStatus}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Reset />
        </Form>
      </template>,
    )

    assert.dom('[data-test-field-status]').hasText('idle')
    assert.dom('[data-test-field-is-not]').hasText('')
    await ui.name.fillIn('Grace')
    assert.dom('[data-test-field-status]').hasText('pending')
    assert.dom('[data-test-field-is]').hasText('pending')
    assert.dom('[data-test-field-is-not]').hasText('busy')
    await ui.name.commit()
    assert.dom('[data-test-field-status]').hasText('idle')
    assert.strictEqual(user.name, 'Grace')

    await ui.name.fillIn('Hopper')
    await ui.name.cancel()
    assert.dom('[data-test-field-status]').hasText('idle', 'cancel')

    await ui.name.fillIn('Hopper')
    await ui.reset()
    assert.dom('[data-test-field-status]').hasText('idle', 'a reset discards the pending value')
    assert.strictEqual(FieldStatus.Idle.value, 'idle')
  })

  test('an inline field goes idle → editing, and stays editing while it holds a value', async function (assert) {
    const user = new User()

    await render(
      <template>
        <Form @model={{user}} @inline={{true}} @layout={{WithStatus}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    assert.dom('[data-test-field-status]').hasText('idle')
    await ui.name.edit()
    assert.dom('[data-test-field-status]').hasText('editing')
    await ui.name.fillIn('Grace')
    assert.dom('[data-test-field-status]').hasText('editing', 'still in the inline editor')
    await ui.name.commit()
    assert.dom('[data-test-field-status]').hasText('idle')
    assert.strictEqual(user.name, 'Grace')
  })
})
