import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled, click } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { Form, type ErrorMap } from '@formwright/ember'
import { TestForm } from 'test-app/tests/helpers/test-form'

class User {
  @tracked name: string
  constructor(name: string) {
    this.name = name
  }
}

class Holder {
  @tracked user: User
  @tracked show = true
  constructor(user: User) {
    this.user = user
  }
}

const SIZES = [
  { id: 's', label: 'Small' },
  { id: 'm', label: 'Medium' },
]

module('Integration | review fixes', function (hooks) {
  setupRenderingTest(hooks)

  let ui: TestForm
  hooks.beforeEach(function () {
    ui = new TestForm()
  })

  test('swapping @model takes a fresh baseline; reset never writes one model into another', async function (assert) {
    const ada = new User('Ada')
    const grace = new User('Grace')
    const holder = new Holder(ada)

    await render(
      <template>
        <Form @model={{holder.user}} as |f|>
          <f.Field @for="name" @label="Name" />
          <span data-test-dirty>{{if f.state.isDirty "dirty" "clean"}}</span>
          <f.Reset />
        </Form>
      </template>,
    )

    holder.user = grace
    await settled()
    assert.dom('[data-test-dirty]').hasText('clean')
    await ui.name.fillIn('Hopper')
    await ui.reset()
    assert.strictEqual(grace.name, 'Grace')
    assert.strictEqual(ada.name, 'Ada')
  })

  test('autoSubmit with a slow save resubmits changes made while saving', async function (assert) {
    const sent: string[] = []
    const user = new User('a')
    const onSubmit = async (m: User) => {
      sent.push(m.name)
      await new Promise(r => setTimeout(r, 30))
    }

    await render(
      <template>
        <Form @model={{user}} @autoSubmit={{true}} @onSubmit={{onSubmit}} as |f|>
          <f.Field @for="name" @label="Name" />
          <span data-test-dirty>{{if f.state.isDirty "dirty" "clean"}}</span>
        </Form>
      </template>,
    )

    const input = document.querySelector<HTMLInputElement>('[data-test-fw-field="name"] input')!
    for (const value of ['b', 'bc', 'bcd']) {
      input.value = value
      input.dispatchEvent(new Event('input', { bubbles: true }))
    }
    await settled()
    assert.strictEqual(sent.at(-1), 'bcd', 'the last value is saved')
    assert.true(sent.length <= 2, 'changes during a save coalesce into one more save')
    assert.dom('[data-test-dirty]').hasText('clean')
  })

  test('a second submit during async validation is ignored', async function (assert) {
    let saves = 0
    const model = { name: 'x', save: () => (saves++, Promise.resolve()) }
    const validator = async (): Promise<ErrorMap> => {
      await new Promise(r => setTimeout(r, 20))
      return {}
    }

    await render(
      <template>
        <Form @model={{model}} @validator={{validator}} as |f|>
          <f.Field @for="name" @label="Name" />
          <f.Submit />
        </Form>
      </template>,
    )

    void click('[data-test-fw-submit]')
    void click('[data-test-fw-submit]')
    await settled()
    assert.strictEqual(saves, 1)
  })

  test('readonly blocks option controls too', async function (assert) {
    const model = { size: 's', sizes: ['s'], pick: 's' }

    await render(
      <template>
        <Form @model={{model}} @readonly={{true}} as |f|>
          <f.Field
            @for="size"
            @control="select"
            @label="Size"
            @options={{SIZES}}
            @storeKey={{true}}
          />
          <f.Field
            @for="pick"
            @control="radio"
            @label="Pick"
            @options={{SIZES}}
            @storeKey={{true}}
          />
          <f.Field
            @for="sizes"
            @control="checkbox-group"
            @label="Sizes"
            @options={{SIZES}}
            @storeKey={{true}}
          />
        </Form>
      </template>,
    )

    assert.dom('select').isDisabled()
    assert.dom('[data-test-fw-field="pick"] [data-test-fw-option="m"]').isDisabled()
    assert.dom('[data-test-fw-field="sizes"] [data-test-fw-option="m"]').isDisabled()
  })

  test('errors with no field to show them appear in <f.Errors>', async function (assert) {
    const model = { name: 'x', secret: '' }
    const validator = () => ({ secret: ['Secret is required'] })

    await render(
      <template>
        <Form @model={{model}} @validator={{validator}} as |f|>
          <f.Errors />
          <f.Field @for="name" @label="Name" />
        </Form>
      </template>,
    )

    await ui.submit()
    assert.deepEqual(ui.errors, ['Secret is required'])
  })

  test("a nested form's failedSubmit hears about its own save failing", async function (assert) {
    let childFailure: unknown
    const user = { name: 'a', address: { city: '', save: () => Promise.reject(new Error('nope')) } }
    const failedChild = (e: unknown) => (childFailure = e)
    const failedRoot = () => {}

    await render(
      <template>
        <Form @model={{user}} @failedSubmit={{failedRoot}} as |f|>
          <f.Form @model={{user.address}} @name="address" @failedSubmit={{failedChild}} as |a|>
            <a.Field @for="city" @label="City" />
          </f.Form>
        </Form>
      </template>,
    )

    await ui.address.city.fillIn('Lisbon')
    await ui.submit()
    assert.strictEqual((childFailure as Error)?.message, 'nope')
  })

  test('Field forwards @currency, @locale, @maxLength and @showCount', async function (assert) {
    const model = { price: 5, bio: 'hi' }

    await render(
      <template>
        <Form @model={{model}} as |f|>
          <f.Field
            @for="price"
            @control="currency"
            @label="Price"
            @currency="EUR"
            @locale="de-DE"
          />
          <f.Field
            @for="bio"
            @control="textarea"
            @label="Bio"
            @maxLength={{10}}
            @showCount={{true}}
          />
        </Form>
      </template>,
    )

    assert.true(
      document
        .querySelector<HTMLInputElement>('[data-test-fw-field="price"] input')!
        .value.includes('€'),
    )
    assert.dom('[data-test-fw-count]').hasText('2 / 10')
  })

  test('saving updates the baseline of fields that are not rendered', async function (assert) {
    const holder = new Holder(new User('Ada'))

    await render(
      <template>
        <Form @model={{holder.user}} as |f|>
          {{#if holder.show}}<f.Field @for="name" @label="Name" />{{/if}}
          <f.Reset />
        </Form>
      </template>,
    )

    await ui.name.fillIn('Grace')
    holder.show = false
    await settled()
    await ui.submit()
    await ui.reset()
    assert.strictEqual(holder.user.name, 'Grace')
  })
})
