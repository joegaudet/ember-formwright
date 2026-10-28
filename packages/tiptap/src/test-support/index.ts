import { click, settled } from '@ember/test-helpers'
import { FieldHarness } from '@ember-formwright/test-support'
import type { Editor } from '@tiptap/core'

/**
 * Drives a `rich-text` field. Text goes in through the editor's own commands (ProseMirror
 * doesn't react to synthetic key events); formatting goes through the toolbar, as a user's
 * would:
 *
 *   class PostForm extends FormHarness {
 *     @field(RichTextHarness) declare body: RichTextHarness
 *   }
 *
 *   await form.body.typeText('Hello')
 *   await form.body.selectAll()
 *   await form.body.press('bold')
 *   assert.strictEqual(form.body.html, '<p><strong>Hello</strong></p>')
 */
export class RichTextHarness extends FieldHarness {
  static override controls = ['rich-text']

  /** The editable element (the one with the field's id). */
  get editorElement(): HTMLElement {
    return this.control
  }

  /** The Tiptap editor behind the field. */
  get editor(): Editor {
    const editor = (this.editorElement as HTMLElement & { editor?: Editor }).editor
    if (!editor) throw new Error(`Formwright harness: no editor in "${this.path}"`)
    return editor
  }

  /** The document as HTML. */
  get html(): string {
    return this.editor.getHTML()
  }

  /** The document as plain text, blocks separated by blank lines. */
  get text(): string {
    return this.editor.getText()
  }

  get isEditable(): boolean {
    return this.editor.isEditable
  }

  /** The toolbar's button names, in order. */
  get tools(): string[] {
    return [...this.element.querySelectorAll('[data-test-fw-tool]')].map(button =>
      button.getAttribute('data-test-fw-tool')!,
    )
  }

  /** Replaces the document, as pasting over all of it would; the cursor ends up at the end. */
  async setContent(html: string): Promise<void> {
    this.editor.chain().setContent(html).focus('end').run()
    await settled()
  }

  /** Inserts text at the cursor (at the end, if the editor isn't focused). */
  async typeText(text: string): Promise<void> {
    const editor = this.editor
    editor
      .chain()
      .focus(editor.isFocused ? undefined : 'end')
      .insertContent(text)
      .run()
    await settled()
  }

  /** Selects the whole document, e.g. before pressing a button. */
  async selectAll(): Promise<void> {
    this.editor.chain().focus().selectAll().run()
    await settled()
  }

  /** Clicks a toolbar button: `bold`, `heading-2`, `bullet-list`, `undo`, ... */
  async press(tool: string): Promise<void> {
    await click(this.tool(tool))
  }

  /** Whether a toolbar button is pressed (its mark or block is active at the cursor). */
  isActive(tool: string): boolean {
    return this.tool(tool).getAttribute('aria-pressed') === 'true'
  }

  private tool(name: string): HTMLButtonElement {
    const button = this.element.querySelector<HTMLButtonElement>(
      `[data-test-fw-tool="${CSS.escape(name)}"]`,
    )
    if (!button) throw new Error(`Formwright harness: no "${name}" button in "${this.path}"`)
    return button
  }
}
