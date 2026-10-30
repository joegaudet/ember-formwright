# Rich text

`@ember-formwright/tiptap` adds a rich-text editor, built on [Tiptap](https://tiptap.dev) 3
and its StarterKit: headings, bold, italic, strikethrough, lists, quotes, undo and redo, with
a toolbar and Tiptap's markdown shortcuts.

```bash
npm install @ember-formwright/tiptap @tiptap/core @tiptap/pm @tiptap/starter-kit
```

```ts
// app/app.ts
import { registerTiptapControl } from '@ember-formwright/tiptap'
import '@ember-formwright/tiptap/theme.css' // optional: follows the Formwright theme

registerTiptapControl() // @control="rich-text"
```

## Writing and formatting

The field stores HTML. Select some text and press a toolbar button, or type a shortcut:
`Ctrl`/`⌘`+`B` for bold, `## ` at the start of a line for a heading, `- ` for a list. Each
button shows whether its formatting is active at the cursor (`aria-pressed`).

<Example @name="controls-rich-text" @title="A rich-text body, stored as HTML" />

An empty editor stores `''`, so a required check works as it does for a textarea. A value set
from outside (a reset, a rollback, a record reloading) replaces the document without counting
as a change.

## Choosing the toolbar, storing JSON

Arguments for the editor go on `field.Control`:

| Argument      |                                                                                                                                                           |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@output`     | `"html"` (default) stores an HTML string; `"json"` stores Tiptap's JSON document, and `null` when empty.                                                  |
| `@toolbar`    | The buttons to show: `bold`, `italic`, `strike`, `heading-2`, `heading-3`, `bullet-list`, `ordered-list`, `blockquote`, `undo`, `redo`. `false` hides it. |
| `@extensions` | More Tiptap extensions, added after StarterKit.                                                                                                           |
| `@starterKit` | StarterKit's options, e.g. `{ heading: { levels: [2, 3] } }`.                                                                                             |

`@extensions` and `@starterKit` are read once, when the editor is created.

<Example @name="controls-rich-text-json" @title="A comment box: three buttons, stored as JSON" />

## Inline forms

An inline form shows a field's value as text, and HTML isn't text. Give the field
`toPlainText` as its `@format`; it reads HTML and JSON alike:

```gts
import { toPlainText } from '@ember-formwright/tiptap'

<Form @model={{@post}} @inline={{true}} as |f|>
  <f.Field @for="body" @control="rich-text" @label="Body" @format={{toPlainText}} />
</Form>
```

In confirm and inline modes, Enter starts a new paragraph rather than committing the edit;
commit with ✓, and Escape cancels as usual.

## Testing

`RichTextHarness`, from `@ember-formwright/tiptap/test-support`, adds `html`, `text`,
`setContent(html)`, `typeText(text)`, `selectAll()`, `press(button)`, `isActive(button)`,
`tools`, `isEditable` and `editor` (the Tiptap editor) to
[`FieldHarness`](../going-further/testing.md#field-harnesses). Text goes in through Tiptap's
commands, since ProseMirror doesn't react to synthetic key events; formatting goes through the
toolbar, as a user's would. Each example's **Test** tab uses it.

<div class="callout">

**Known limits**

- The editor is a `div` with `role="textbox"`, which `<label for>` doesn't name. The control
  passes the field's `@label` as `aria-label`, and a click on the label focuses the editor.
- It doesn't submit with a native `<form>`: there is no `<input name>`. The control sets
  `data-fw-name` with the field's path.
- The stored HTML is whatever Tiptap's schema allows, but it is still user input: sanitize it
  on the server before you render it anywhere else.

</div>
