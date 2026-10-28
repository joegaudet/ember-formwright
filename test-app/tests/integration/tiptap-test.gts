import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, click, settled, triggerKeyEvent } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { FormHarness, field } from '@ember-formwright/test-support'
import { registerTiptapControl, toPlainText, type RichTextValue } from '@ember-formwright/tiptap'
import { RichTextHarness } from '@ember-formwright/tiptap/test-support'

registerTiptapControl()

class Post {
  @tracked body: RichTextValue = ''
}

class Toggle {
  @tracked show = true
}

class PostForm extends FormHarness {
  @field(RichTextHarness) declare body: RichTextHarness
}

const requireBody = (post: Post): ErrorMap => (post.body ? {} : { body: ['Write something'] })

module('Integration | tiptap', function (hooks) {
  setupRenderingTest(hooks)

  let ui: PostForm
  hooks.beforeEach(function () {
    ui = new PostForm()
  })

  test('the editor is wired to the field, and typing stores HTML', async function (assert) {
    const post = new Post()
    await render(
      <template>
        <Form @model={{post}} as |f|>
          <f.Field
            @for="body"
            @control="rich-text"
            @label="Body"
            @hint="Markdown shortcuts work"
            @placeholder="Say something"
            @required={{true}}
          />
        </Form>
      </template>,
    )

    const editor = ui.body.editorElement
    assert.dom('[data-test-fw-field="body"] label').hasAttribute('for', editor.id)
    assert
      .dom(editor)
      .hasAttribute('role', 'textbox')
      .hasAttribute('contenteditable', 'true')
      .hasAttribute('aria-multiline', 'true')
      .hasAttribute('aria-label', 'Body')
      .hasAttribute('aria-required', 'true')
      .hasAttribute('aria-describedby', `${editor.id}-hint`)
      .hasAttribute('aria-placeholder', 'Say something')
      .hasAttribute('data-empty')
      .hasClass('fw-rich-text-editor')
    assert
      .dom('[data-test-fw-field="body"] [data-test-fw-control]')
      .hasAttribute('data-test-fw-control', 'rich-text')
      .hasAttribute('data-fw-name', 'form.body')
    assert.dom('[role="toolbar"]').hasAttribute('aria-label', 'Formatting')
    assert.deepEqual(ui.body.tools, [
      'bold',
      'italic',
      'strike',
      'heading-2',
      'heading-3',
      'bullet-list',
      'ordered-list',
      'blockquote',
      'undo',
      'redo',
    ])

    await ui.body.typeText('Hello')
    assert.strictEqual(post.body, '<p>Hello</p>')
    assert.dom(editor).doesNotHaveAttribute('data-empty')
    assert.true(ui.isDirty)
    await a11yAudit()
  })

  test('toolbar buttons toggle formatting and show it as pressed', async function (assert) {
    const post = new Post()
    post.body = '<p>Hello</p>'
    await render(
      <template>
        <Form @model={{post}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" />
        </Form>
      </template>,
    )

    assert.strictEqual(ui.body.html, '<p>Hello</p>', 'starts from the model')
    assert.false(ui.body.isActive('bold'))
    assert.dom('[data-test-fw-tool="bold"]').hasAttribute('aria-pressed', 'false')
    assert.dom('[data-test-fw-tool="undo"]').doesNotHaveAttribute('aria-pressed')
    assert.dom('[data-test-fw-tool="undo"]').isDisabled('nothing to undo yet')

    await ui.body.selectAll()
    await ui.body.press('bold')
    assert.strictEqual(post.body, '<p><strong>Hello</strong></p>')
    assert.true(ui.body.isActive('bold'), 'bold is pressed')
    assert.dom('[data-test-fw-tool="undo"]').isNotDisabled()

    await ui.body.press('undo')
    assert.strictEqual(post.body, '<p>Hello</p>')
    assert.false(ui.body.isActive('bold'), 'bold is not pressed')
    await ui.body.press('redo')
    assert.strictEqual(post.body, '<p><strong>Hello</strong></p>')

    // Block buttons apply at the cursor.
    await ui.body.setContent('')
    await ui.body.press('heading-2')
    assert.true(ui.body.isActive('heading-2'), 'heading-2 is pressed')
    assert.false(ui.body.isActive('heading-3'))
    await ui.body.typeText('Title')
    assert.strictEqual(post.body, '<h2>Title</h2>')

    await ui.body.press('bullet-list')
    assert.true(ui.body.isActive('bullet-list'), 'bullet-list is pressed')
    assert.false(ui.body.isActive('heading-2'), 'a list item is a paragraph')
    assert.strictEqual(post.body, '<ul><li><p>Title</p></li></ul>')
  })

  test('clicking the label focuses the editor', async function (assert) {
    const post = new Post()
    await render(
      <template>
        <Form @model={{post}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" />
        </Form>
      </template>,
    )
    await click('[data-test-fw-field="body"] label')
    assert.strictEqual(document.activeElement, ui.body.editorElement)
  })

  test('@toolbar picks the buttons, and false hides the toolbar', async function (assert) {
    const post = new Post()
    const tools = ['bold', 'italic', 'undo'] as const
    await render(
      <template>
        <Form @model={{post}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" as |field|>
            <field.Control @toolbar={{tools}} />
          </f.Field>
        </Form>
        <Form @model={{post}} @name="bare" as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" as |field|>
            <field.Control @toolbar={{false}} />
          </f.Field>
        </Form>
      </template>,
    )
    assert.deepEqual(ui.body.tools, ['bold', 'italic', 'undo'])
    assert.dom('[data-test-fw-form="form"] .fw-rich-text-group').exists({ count: 2 })
    assert.dom('[data-test-fw-form="bare"] [role="toolbar"]').doesNotExist()
  })

  test('@output="json" stores the Tiptap document; empty stores null', async function (assert) {
    const post = new Post()
    post.body = null
    await render(
      <template>
        <Form @model={{post}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" as |field|>
            <field.Control @output="json" />
          </f.Field>
        </Form>
      </template>,
    )
    await ui.body.typeText('Hi')
    assert.deepEqual(post.body, {
      type: 'doc',
      content: [{ type: 'paragraph', content: [{ type: 'text', text: 'Hi' }] }],
    })
    await ui.body.setContent('')
    assert.strictEqual(post.body, null)
  })

  test('an emptied editor stores "", so required validation fails', async function (assert) {
    const post = new Post()
    post.body = '<p>Draft</p>'
    await render(
      <template>
        <Form @model={{post}} @validator={{requireBody}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" />
          <f.Submit>Save</f.Submit>
        </Form>
      </template>,
    )
    await ui.body.setContent('')
    assert.strictEqual(post.body, '')
    await ui.submit()
    assert.deepEqual(ui.body.errors, ['Write something'])
    assert.dom(ui.body.editorElement).hasAttribute('aria-invalid', 'true')
    await a11yAudit()

    await ui.body.typeText('Better')
    assert.deepEqual(ui.body.errors, [], 'errors clear as it is fixed')
  })

  test('reset puts the saved content back without a change', async function (assert) {
    const post = new Post()
    post.body = '<p>Saved</p>'
    let changes = 0
    const onChange = () => changes++
    await render(
      <template>
        <Form @model={{post}} @onChange={{onChange}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" />
          <f.Reset>Reset</f.Reset>
        </Form>
      </template>,
    )
    await ui.body.typeText(' and edited')
    assert.strictEqual(post.body, '<p>Saved and edited</p>')
    assert.strictEqual(changes, 1)

    await ui.reset()
    assert.strictEqual(post.body, '<p>Saved</p>')
    assert.strictEqual(ui.body.html, '<p>Saved</p>', 'the editor shows it')
    assert.strictEqual(changes, 1, 'setting content from outside is not a change')

    post.body = '<p>From the server</p>'
    await settled()
    assert.strictEqual(ui.body.html, '<p>From the server</p>')
  })

  test('disabled and readonly make it read-only, toolbar included', async function (assert) {
    const post = new Post()
    post.body = '<p>Locked</p>'
    await render(
      <template>
        <Form @model={{post}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" @disabled={{true}} />
        </Form>
        <Form @model={{post}} @name="ro" @readonly={{true}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" />
        </Form>
      </template>,
    )
    assert.false(ui.body.isEditable)
    assert.dom(ui.body.editorElement).hasAttribute('contenteditable', 'false')
    assert.dom(ui.body.editorElement).hasAttribute('aria-disabled', 'true')
    assert.dom('[data-test-fw-form="form"] [data-test-fw-tool="bold"]').isDisabled()

    const readonly = new PostForm('ro')
    assert.false(readonly.body.isEditable)
    assert.dom(readonly.body.editorElement).hasAttribute('aria-readonly', 'true')
    assert.dom('[data-test-fw-form="ro"] [data-test-fw-tool="bold"]').isDisabled()
    await a11yAudit()
  })

  test('Enter makes a paragraph and does not commit a confirm-mode field', async function (assert) {
    const post = new Post()
    post.body = '<p>One</p>'
    await render(
      <template>
        <Form @model={{post}} @requireConfirm={{true}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" />
        </Form>
      </template>,
    )
    await ui.body.typeText(' more')
    assert.strictEqual(post.body, '<p>One</p>', 'waits for confirm')
    await triggerKeyEvent(ui.body.editorElement, 'keydown', 'Enter')
    assert.strictEqual(post.body, '<p>One</p>', 'Enter stays in the editor')
    assert.strictEqual(ui.body.html, '<p>One more</p><p></p>', 'and starts a paragraph')
    assert.dom('[data-test-fw-commit]').exists()

    await ui.body.commit()
    assert.strictEqual(post.body, '<p>One more</p>')
  })

  test('inline: shows plain text with toPlainText, edits on click', async function (assert) {
    const post = new Post()
    post.body = '<h2>Title</h2><p>Some <strong>bold</strong> words</p>'
    await render(
      <template>
        <Form @model={{post}} @inline={{true}} as |f|>
          <f.Field @for="body" @control="rich-text" @label="Body" @format={{toPlainText}} />
        </Form>
      </template>,
    )
    assert.strictEqual(ui.body.displayText, 'Title Some bold words')
    await ui.body.edit()
    assert.strictEqual(document.activeElement, ui.body.editorElement, 'focuses the editor')
    await ui.body.setContent('<p>Rewritten</p>')
    assert.strictEqual(post.body, '<h2>Title</h2><p>Some <strong>bold</strong> words</p>')
    await ui.body.commit()
    assert.strictEqual(post.body, '<p>Rewritten</p>')
    assert.strictEqual(ui.body.displayText, 'Rewritten')
  })

  test('toPlainText reads HTML and JSON', function (assert) {
    assert.strictEqual(toPlainText('<p>a</p><ul><li><p>b</p></li></ul>'), 'a b')
    assert.strictEqual(toPlainText(''), '')
    assert.strictEqual(toPlainText(null), '')
    assert.strictEqual(
      toPlainText({
        type: 'doc',
        content: [
          { type: 'paragraph', content: [{ type: 'text', text: 'a' }] },
          { type: 'paragraph', content: [{ type: 'text', text: 'b' }] },
        ],
      }),
      'a b',
    )
  })

  test('the editor is destroyed with the field', async function (assert) {
    const post = new Post()
    const state = new Toggle()
    await render(
      <template>
        <Form @model={{post}} as |f|>
          {{#if state.show}}
            <f.Field @for="body" @control="rich-text" @label="Body" />
          {{/if}}
        </Form>
      </template>,
    )
    const editor = ui.body.editor
    state.show = false
    await settled()
    assert.true(editor.isDestroyed)
  })
})
