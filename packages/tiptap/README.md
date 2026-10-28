# @ember-formwright/tiptap

A rich-text control for Formwright, powered by [Tiptap](https://tiptap.dev) 3 and its
StarterKit.

```bash
npm install @ember-formwright/ember @ember-formwright/tiptap @tiptap/core @tiptap/pm @tiptap/starter-kit
```

```ts
// app/app.ts
import { registerTiptapControl } from '@ember-formwright/tiptap'
import '@ember-formwright/tiptap/theme.css' // optional; after the Formwright theme

registerTiptapControl() // @control="rich-text"
```

```gts
<f.Field @for="body" @control="rich-text" @label="Body" @placeholder="Write something" />

{{! a trimmed toolbar, storing Tiptap JSON }}
<f.Field @for="comment" @control="rich-text" @label="Comment" as |field|>
  <field.Control @toolbar={{array "bold" "italic" "bullet-list"}} @output="json" />
</f.Field>

{{! inline forms show the value as text }}
<f.Field @for="body" @control="rich-text" @format={{toPlainText}} />
```

The field stores HTML, or Tiptap's JSON document with `@output="json"`. An empty editor
stores `''` (`null` for JSON), so required checks work. `field.Control` also takes `@toolbar`
(the buttons to show, or `false`), `@extensions` (more Tiptap extensions) and `@starterKit`
(StarterKit's options); the last two are read once, when the editor is created.

Toolbar buttons: `bold`, `italic`, `strike`, `heading-2`, `heading-3`, `bullet-list`,
`ordered-list`, `blockquote`, `undo`, `redo`. Each has an accessible name, and the toggles
carry `aria-pressed`.

## Testing

```ts
import { RichTextHarness } from '@ember-formwright/tiptap/test-support'

class PostForm extends FormHarness {
  @field(RichTextHarness) declare body: RichTextHarness
}

await post.body.typeText('Hello')
await post.body.selectAll()
await post.body.press('bold')
assert.true(post.body.isActive('bold'))
assert.strictEqual(post.body.html, '<p><strong>Hello</strong></p>')
```

It also has `text`, `setContent(html)`, `tools`, `isEditable` and `editor` (the Tiptap
editor). Text goes in through Tiptap's commands: ProseMirror doesn't react to synthetic key
events.

## Behaviour and known limits

- **Outside changes.** A new value from the model (reset, rollback, a reload) replaces the
  document without a change event. Typing never re-sets the document.
- **Trailing paragraph.** StarterKit keeps an empty paragraph after a final list or heading,
  so there is somewhere to type. It isn't stored.
- **Keyboard.** Enter starts a paragraph and doesn't reach the field, so in confirm and
  inline modes it doesn't commit; use ✔. Escape cancels as usual.
- **Disabled and read-only.** The editor stops being editable and the toolbar is disabled.
- **Labels.** The editor is a `div role="textbox"`, which `<label for>` doesn't name; the
  control passes `@label` as `aria-label`, and a click on the label focuses the editor.
- **Native submit.** There is no `<input name>`; the wrapper carries `data-fw-name` with the
  field's path.
- **Sanitize.** Tiptap's schema limits what the editor produces, but the HTML is still user
  input. Sanitize it on the server before rendering it elsewhere.
- **Versions.** Ember 6.12+ and Tiptap 3.
