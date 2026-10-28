import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, fillIn } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { Form, pojoAdapter, type ModelAdapter } from '@ember-formwright/ember'
import { DEFAULT_FIELD_DOM } from 'test-app/tests/fixtures/default-field-dom'

const SIZES = [
  { id: 's', label: 'Small' },
  { id: 'm', label: 'Medium' },
]

class Model {
  @tracked name = 'Ada'
  @tracked email = 'nope'
  @tracked size = 's'
  @tracked sizes: string[] = ['m']
  @tracked agree = false
  @tracked bio = ''
  @tracked nick = 'ace'
  @tracked city = 'Lisbon'
}

/** Server-style errors, so the snapshot has an error without an async submit. */
const adapter: ModelAdapter<Model> = {
  ...pojoAdapter,
  errorsFor: (_model, path) => (path === 'email' ? ['That email looks off'] : []),
}

/**
 * The markup of every field, normalized: ids renumbered in order of appearance, comments and
 * the whitespace between tags dropped. Glimmer's ids and whitespace are not markup.
 */
function normalize(root: Element): string {
  const ids = new Map<string, string>()
  return root.innerHTML
    .replace(/<!---->/g, '')
    .replace(/>\s+</g, '><')
    .replace(/\s+/g, ' ')
    .replace(/ember\d+/g, match => {
      if (!ids.has(match)) ids.set(match, `ember${ids.size + 1}`)
      return ids.get(match)!
    })
    .trim()
}

module('Integration | default field markup', function (hooks) {
  setupRenderingTest(hooks)

  test('the default layout renders the same markup as before layouts existed', async function (assert) {
    const model = new Model()

    await render(
      <template>
        <div data-test-snapshot>
          <Form @model={{model}} @adapter={{adapter}} @name="plain" as |f|>
            <f.Field
              @for="email"
              @control="email"
              @label="Email"
              @hint="We never share it."
              @placeholder="you@example.com"
              @required={{true}}
            />
            <f.Field @for="name" />
            <f.Field
              @for="size"
              @control="select"
              @label="Size"
              @options={{SIZES}}
              @storeKey={{true}}
            />
            <f.Field
              @for="size"
              @control="radio"
              @label="Size"
              @hint="Pick one"
              @options={{SIZES}}
              @storeKey={{true}}
              @required={{true}}
            />
            <f.Field
              @for="sizes"
              @control="checkbox-group"
              @label="Sizes"
              @options={{SIZES}}
              @storeKey={{true}}
            />
            <f.Field @for="agree" @control="checkbox" @label="I agree" @disabled={{true}} />
            <f.Field @for="bio" @control="textarea" @label="Bio" as |field|>
              <div class="composer">
                <field.Control @maxLength={{20}} @showCount={{true}} />
                <small>{{field.id}}</small>
              </div>
            </f.Field>
            <f.Field @for="nick" @label="Nick" @requireConfirm={{true}} />
          </Form>
          <Form @model={{model}} @inline={{true}} @name="inline" as |f|>
            <f.Field @for="name" @label="Name" @placeholder="Add a name" />
            <f.Field
              @for="size"
              @control="select"
              @label="Size"
              @options={{SIZES}}
              @storeKey={{true}}
            />
          </Form>
          <Form @model={{model}} @inline={{true}} @callout={{true}} @name="callout" as |f|>
            <f.Field @for="city" @label="City" />
          </Form>
        </div>
      </template>,
    )

    await fillIn('[data-test-fw-form="plain"] [data-test-fw-field="nick"] input', 'ace!')
    await click('[data-test-fw-form="callout"] [data-test-fw-display]')

    const actual = normalize(document.querySelector('[data-test-snapshot]')!)
    assert.strictEqual(actual, DEFAULT_FIELD_DOM)
  })
})
