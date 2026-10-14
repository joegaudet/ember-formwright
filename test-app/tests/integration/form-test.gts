import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, settled, focus, triggerKeyEvent } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { z } from 'zod'
import * as v from 'valibot'
import { Form, type ErrorMap } from '@formwright/ember'
import { form } from '@formwright/test-support'

class User {
  @tracked name = 'Ada'
  @tracked email = ''
  @tracked age = 36
}

module('Integration | Form', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a <form> with stable selectors and binds values both ways', async function (assert) {
    const user = { name: 'Ada', email: '' }

    await render(
      <template>
        <Form @model={{user}} @name="signup" as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Field @for="email" @control="email" @label="Email" />
        </Form>
      </template>,
    )

    assert.dom('form[data-test-fw-form="signup"]').exists()
    assert.dom('[data-test-fw-field="name"] [data-test-fw-label]').hasText('Name')
    assert.strictEqual(form('signup').field('name').value, 'Ada')

    await form('signup').field('email').fillIn('ada@example.com')
    assert.strictEqual(user.email, 'ada@example.com', 'POJO model updated')
    assert.dom('[data-test-fw-field="email"] input').hasAttribute('type', 'email')
  })

  test('labels, hints and errors are wired for assistive tech', async function (assert) {
    const user = new User()
    const validator = (m: User): ErrorMap => (m.email ? {} : { email: ['Email is required'] })

    await render(
      <template>
        <Form @model={{user}} @validator={{validator}} as |f|>
          <f.Field @for="email" @label="Email" @hint="We never share it" @required={{true}} />
          <f.Submit />
        </Form>
      </template>,
    )

    const input = '[data-test-fw-field="email"] input'
    const id = document.querySelector(input)!.id
    assert.dom(`label[for="${id}"]`).exists('label points at the control')
    assert.dom(input).hasAttribute('required')
    assert.dom(input).doesNotHaveAttribute('aria-invalid')

    await form().submit()

    assert.deepEqual(form().field('email').errors, ['Email is required'])
    assert.dom(input).hasAttribute('aria-invalid', 'true')
    const describedBy = document.querySelector(input)!.getAttribute('aria-describedby')!.split(' ')
    assert.strictEqual(describedBy.length, 2, 'hint and errors both describe the control')
    for (const ref of describedBy) assert.dom(`#${ref}`).exists()
    assert.dom(input).isFocused('first invalid control is focused')

    await a11yAudit()
    assert.ok(true, 'axe passes with errors showing')
  })

  test('a Standard Schema validator (zod) blocks submit and maps issue paths', async function (assert) {
    const model = { email: 'nope', address: { city: '' } }
    const schema = z.object({
      email: z.string().email('Not an email'),
      address: z.object({ city: z.string().min(1, 'City is required') }),
    })
    let submitted = 0
    const onSubmit = () => submitted++

    await render(
      <template>
        <Form @model={{model}} @validator={{schema}} @onSubmit={{onSubmit}} as |f|>
          <f.Field @for="email" @label="Email" />
          <f.Field @for="address.city" @label="City" />
        </Form>
      </template>,
    )

    await form().submit()
    assert.strictEqual(submitted, 0)
    assert.deepEqual(form().field('email').errors, ['Not an email'])
    assert.deepEqual(form().field('address.city').errors, ['City is required'])

    await form().field('email').fillIn('a@b.co')
    assert.deepEqual(
      form().field('email').errors,
      [],
      'revalidates on change after a failed submit',
    )

    await form().field('address.city').fillIn('Lisbon')
    await form().submit()
    assert.strictEqual(submitted, 1)
  })

  test('a Standard Schema validator (valibot) works too', async function (assert) {
    const model = { name: '' }
    const schema = v.object({ name: v.pipe(v.string(), v.minLength(2, 'Too short')) })

    await render(
      <template>
        <Form @model={{model}} @validator={{schema}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    await form().submit()
    assert.deepEqual(form().field('name').errors, ['Too short'])
  })

  test('form-level errors render in <f.Errors>', async function (assert) {
    const model = { a: '' }
    const validator = () => ({ '': ['Something is off'] })

    await render(
      <template>
        <Form @model={{model}} @validator={{validator}} as |f|>
          <f.Errors />
          <f.Field @for="a" @label="A" />
        </Form>
      </template>,
    )

    await form().submit()
    assert.deepEqual(form().errors, ['Something is off'])
  })

  test('submit calls model.save() by default, and lifecycle hooks in order', async function (assert) {
    const calls: string[] = []
    const model = {
      name: 'x',
      save() {
        calls.push('save')
        return Promise.resolve()
      },
    }
    const willSubmit = () => (calls.push('willSubmit'), true)
    const didSubmit = () => calls.push('didSubmit')

    await render(
      <template>
        <Form @model={{model}} @willSubmit={{willSubmit}} @didSubmit={{didSubmit}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Submit />
        </Form>
      </template>,
    )

    await form().submit()
    assert.deepEqual(calls, ['willSubmit', 'save', 'didSubmit'])
  })

  test('willSubmit returning false cancels; a rejected save calls failedSubmit', async function (assert) {
    let failed: unknown
    let allow = false
    const model = { name: 'x', save: () => Promise.reject(new Error('boom')) }
    const willSubmit = () => allow
    const failedSubmit = (e: unknown) => (failed = e)

    await render(
      <template>
        <Form @model={{model}} @willSubmit={{willSubmit}} @failedSubmit={{failedSubmit}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    await form().submit()
    assert.strictEqual(failed, undefined)

    allow = true
    await form().submit()
    assert.strictEqual((failed as Error).message, 'boom')
  })

  test('submitting with Enter submits the form', async function (assert) {
    let submitted = false
    const model = { name: 'x' }
    const onSubmit = () => (submitted = true)

    await render(
      <template>
        <Form @model={{model}} @onSubmit={{onSubmit}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Submit />
        </Form>
      </template>,
    )

    await click('[data-test-fw-submit]')
    assert.true(submitted)
  })

  test('the submit button is busy while submitting', async function (assert) {
    let finish!: () => void
    const model = { name: 'x' }
    const onSubmit = () => new Promise<void>(r => (finish = r))

    await render(
      <template>
        <Form @model={{model}} @onSubmit={{onSubmit}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )

    click('[data-test-fw-submit]')
    await new Promise(r => setTimeout(r, 10))
    assert.dom('[data-test-fw-submit]').hasAttribute('aria-busy', 'true').hasText('Save')
    assert.dom('form').hasAttribute('data-submitting')
    finish()
    await settled()
    assert.dom('[data-test-fw-submit]').doesNotHaveAttribute('aria-busy')
  })

  test('dirty tracking and reset', async function (assert) {
    const user = new User()

    await render(
      <template>
        <Form @model={{user}} as |f|>
          <f.Field @for="name" @label="Name" />
          <span data-test-dirty>{{if f.state.isDirty "dirty" "clean"}}</span>
          <f.Reset />
        </Form>
      </template>,
    )

    assert.dom('[data-test-dirty]').hasText('clean')
    await form().field('name').fillIn('Grace')
    assert.strictEqual(user.name, 'Grace')
    assert.dom('[data-test-dirty]').hasText('dirty')
    assert.dom('[data-test-fw-field="name"]').hasAttribute('data-dirty')

    await form().reset()
    assert.strictEqual(user.name, 'Ada')
    assert.dom('[data-test-dirty]').hasText('clean')
  })

  test('a successful submit becomes the new clean baseline', async function (assert) {
    const user = new User()

    await render(
      <template>
        <Form @model={{user}} as |f|>
          <f.Field @for="name" @label="Name" />
          <span data-test-dirty>{{if f.state.isDirty "dirty" "clean"}}</span>
          <f.Reset />
        </Form>
      </template>,
    )

    await form().field('name').fillIn('Grace')
    await form().submit()
    assert.dom('[data-test-dirty]').hasText('clean')
    await form().reset()
    assert.strictEqual(user.name, 'Grace')
  })

  test('onChange reports each committed value', async function (assert) {
    const changes: Array<[string, unknown]> = []
    const user = new User()
    const onChange = (path: string, value: unknown) => changes.push([path, value])

    await render(
      <template>
        <Form @model={{user}} @onChange={{onChange}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    await form().field('name').fillIn('Grace')
    assert.deepEqual(changes, [['name', 'Grace']])
  })

  test('disabled and readonly flow down to every control', async function (assert) {
    const user = new User()

    await render(
      <template>
        <Form @model={{user}} @disabled={{true}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
        <Form @model={{user}} @name="ro" @readonly={{true}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    assert.true(form().field('name').isDisabled)
    assert.dom('[data-test-fw-form="ro"] input').hasAttribute('readonly')
  })

  test('autoSubmit submits after every change', async function (assert) {
    let submits = 0
    const user = new User()
    const onSubmit = () => submits++

    await render(
      <template>
        <Form @model={{user}} @autoSubmit={{true}} @onSubmit={{onSubmit}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    await form().field('name').fillIn('Grace')
    assert.strictEqual(submits, 1)
  })

  test('requireConfirm buffers the value until commit, cancel discards it', async function (assert) {
    const user = new User()

    await render(
      <template>
        <Form @model={{user}} @requireConfirm={{true}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    const name = form().field('name')
    assert.dom('[data-test-fw-commit]').doesNotExist('nothing to confirm yet')
    await name.fillIn('Grace')
    assert.strictEqual(user.name, 'Ada', 'not committed yet')
    await name.commit()
    assert.strictEqual(user.name, 'Grace')

    await name.fillIn('Hopper')
    await name.cancel()
    assert.strictEqual(user.name, 'Grace')
    assert.strictEqual(name.value, 'Grace')
  })

  test('inline editing shows the value, then the control', async function (assert) {
    const user = new User()

    await render(
      <template>
        <Form @model={{user}} @inline={{true}} as |f|>
          <f.Field @for="name" @label="Name" @placeholder="Add a name" />
          <f.Field @for="email" @label="Email" @placeholder="Add an email" />
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-field="name"] [data-test-fw-display]').hasText('Ada')
    assert.dom('[data-test-fw-field="email"] [data-test-fw-display]').hasText('Add an email')
    assert.dom('[data-test-fw-field="name"] input').doesNotExist()

    const name = form().field('name')
    await name.edit()
    assert.dom('[data-test-fw-field="name"] input').isFocused()
    await name.fillIn('Grace')
    await name.commit()
    assert.strictEqual(user.name, 'Grace')
    assert.dom('[data-test-fw-field="name"] [data-test-fw-display]').hasText('Grace')
    assert.dom('[data-test-fw-field="name"] input').doesNotExist()
  })

  test('inline editing in a callout uses a native popover; Escape cancels', async function (assert) {
    const user = new User()

    await render(
      <template>
        <Form @model={{user}} @inline={{true}} @callout={{true}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    const name = form().field('name')
    await name.edit()
    const popover = document.querySelector<HTMLElement>('[data-test-fw-field="name"] [popover]')!
    assert.ok(popover, 'renders a popover element')
    assert.true(popover.matches(':popover-open'), 'popover is open')

    await name.fillIn('Grace')
    await triggerKeyEvent(popover, 'keydown', 'Escape')
    popover.hidePopover()
    await settled()
    assert.strictEqual(user.name, 'Ada', 'escape cancels')
    assert.dom('[data-test-fw-field="name"] [popover]').doesNotExist()
  })

  test('a custom formatter controls the displayed value', async function (assert) {
    const user = new User()
    const format = (v: unknown) => `${String(v)} years`

    await render(
      <template>
        <Form @model={{user}} @inline={{true}} as |f|>
          <f.Field @for="age" @label="Age" @format={{format}} />
        </Form>
      </template>,
    )

    assert.dom('[data-test-fw-display]').hasText('36 years')
  })

  test('the block form yields a pre-wired Control for extra args and custom layout', async function (assert) {
    const model = { bio: '' }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field @for="bio" @control="textarea" @label="Bio" as |field|>
            <field.Control @maxLength={{20}} @showCount={{true}} />
            <small data-test-yielded-id>{{field.id}}</small>
          </f.Field>
        </Form>
      </template>,
    )

    await form().field('bio').fillIn('Hello')
    assert.strictEqual(model.bio, 'Hello')
    assert.dom('textarea').hasAttribute('maxlength', '20')
    assert.dom('[data-test-fw-count]').hasText('5 / 20')
    assert.dom('[data-test-yielded-id]').hasText(document.querySelector('textarea')!.id)
  })

  test('nested forms render as fieldsets and submit after their parent', async function (assert) {
    const order: string[] = []
    const address = {
      city: '',
      save() {
        order.push('address')
        return Promise.resolve()
      },
    }
    const user = {
      name: 'Ada',
      address,
      save() {
        order.push('user')
        return Promise.resolve()
      },
    }

    await render(
      <template>
        <Form @model={{user}} @name="user" as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Form @model={{user.address}} @name="address" @legend="Address" as |a|>
            <a.Field @for="city" @label="City" />
          </f.Form>
        </Form>
      </template>,
    )

    assert.dom('form fieldset[data-test-fw-form="address"] legend').hasText('Address')
    assert
      .dom('[data-test-fw-form="address"] [data-test-fw-field="city"]')
      .hasAttribute('data-test-fw-path', 'user.address.city')

    const city = form('user').form('address').field('city')
    await city.fillIn('Lisbon')
    assert.strictEqual(address.city, 'Lisbon')

    await form('user').submit()
    assert.deepEqual(order, ['user', 'address'], 'parent first, then the dirty child')
  })

  test('nested form validators run on the root submit', async function (assert) {
    let saved = false
    const user = {
      address: { city: '' },
      save: () => ((saved = true), Promise.resolve()),
    }
    const cityRequired = (m: { city: string }): ErrorMap => (m.city ? {} : { city: ['Required'] })

    await render(
      <template>
        <Form @model={{user}} @name="user" as |f|>
          <f.Form @model={{user.address}} @name="address" @validator={{cityRequired}} as |a|>
            <a.Field @for="city" @label="City" />
          </f.Form>
        </Form>
      </template>,
    )

    await form('user').submit()
    assert.false(saved)
    assert.deepEqual(form('user').form('address').field('city').errors, ['Required'])
  })

  test('it resets unsaved changes when torn down', async function (assert) {
    class State {
      @tracked show = true
    }
    const state = new State()
    const user = new User()

    await render(
      <template>
        {{#if state.show}}
          <Form @model={{user}} as |f|>
            <f.Field @for="name" @label="Name" />
          </Form>
        {{/if}}
      </template>,
    )

    await form().field('name').fillIn('Grace')
    state.show = false
    await settled()
    assert.strictEqual(user.name, 'Ada')
  })

  test('focus helper sanity: the harness exposes the control element', async function (assert) {
    const user = new User()
    await render(
      <template>
        <Form @model={{user}} as |f|>
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )
    await focus(form().field('name').control!)
    assert.dom('[data-test-fw-field="name"] input').isFocused()
  })
})
