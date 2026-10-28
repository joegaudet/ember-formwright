import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import type Owner from '@ember/owner'
import { tracked } from '@glimmer/tracking'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { modifier } from 'ember-modifier'
import { Editor, type Content, type Extensions, type JSONContent } from '@tiptap/core'
import type { EditorState } from '@tiptap/pm/state'
import StarterKit from '@tiptap/starter-kit'
import { registerControl, type ControlSignature } from '@ember-formwright/ember'

/** A toolbar button, by name. */
export type RichTextTool =
  | 'bold'
  | 'italic'
  | 'strike'
  | 'heading-2'
  | 'heading-3'
  | 'bullet-list'
  | 'ordered-list'
  | 'blockquote'
  | 'undo'
  | 'redo'

/** What the control stores: HTML (a string), or Tiptap's JSON document. */
export type RichTextValue = string | JSONContent | null

interface Tool {
  name: RichTextTool
  label: string
  /** Toggles a mark or node, so it has a pressed state. */
  toggle: boolean
  run: (editor: Editor) => void
  isActive: (editor: Editor) => boolean
  can: (editor: Editor) => boolean
}

const mark = (
  name: RichTextTool,
  label: string,
  type: string,
  run: (editor: Editor) => void,
): Tool => ({
  name,
  label,
  toggle: true,
  run,
  isActive: editor => editor.isActive(type),
  can: () => true,
})

const heading = (level: 2 | 3): Tool => ({
  name: `heading-${level}`,
  label: `Heading ${level}`,
  toggle: true,
  run: editor => editor.chain().focus().toggleHeading({ level }).run(),
  isActive: editor => editor.isActive('heading', { level }),
  can: () => true,
})

const TOOLS: Tool[] = [
  mark('bold', 'Bold', 'bold', e => e.chain().focus().toggleBold().run()),
  mark('italic', 'Italic', 'italic', e => e.chain().focus().toggleItalic().run()),
  mark('strike', 'Strikethrough', 'strike', e => e.chain().focus().toggleStrike().run()),
  heading(2),
  heading(3),
  mark('bullet-list', 'Bulleted list', 'bulletList', e =>
    e.chain().focus().toggleBulletList().run(),
  ),
  mark('ordered-list', 'Numbered list', 'orderedList', e =>
    e.chain().focus().toggleOrderedList().run(),
  ),
  mark('blockquote', 'Quote', 'blockquote', e => e.chain().focus().toggleBlockquote().run()),
  {
    name: 'undo',
    label: 'Undo',
    toggle: false,
    run: e => e.chain().focus().undo().run(),
    isActive: () => false,
    can: e => e.can().undo(),
  },
  {
    name: 'redo',
    label: 'Redo',
    toggle: false,
    run: e => e.chain().focus().redo().run(),
    isActive: () => false,
    can: e => e.can().redo(),
  },
]

/** Buttons are drawn in groups, with a divider between them. */
const GROUPS: RichTextTool[][] = [
  ['bold', 'italic', 'strike'],
  ['heading-2', 'heading-3'],
  ['bullet-list', 'ordered-list', 'blockquote'],
  ['undo', 'redo'],
]

/** Every button, the default `@toolbar`. */
export const DEFAULT_TOOLBAR: readonly RichTextTool[] = GROUPS.flat()

export interface RichTextControlSignature {
  /** The wrapper around the toolbar and the editor. */
  Element: HTMLDivElement
  Args: ControlSignature<RichTextValue>['Args'] & {
    /** `html` (default) stores an HTML string; `json` stores Tiptap's JSON document. */
    output?: 'html' | 'json'
    /** The buttons to show, in groups as listed; `false` hides the toolbar. */
    toolbar?: readonly RichTextTool[] | false
    /** More Tiptap extensions, added after StarterKit. Read once, when the editor is created. */
    extensions?: Extensions
    /** StarterKit's options, e.g. `{ heading: { levels: [2, 3] } }`. Read once. */
    starterKit?: Parameters<typeof StarterKit.configure>[0]
  }
}

/** Whether a document is a single empty paragraph (or heading). */
function isEmptyDoc(state: EditorState): boolean {
  const { doc } = state
  return doc.childCount === 1 && doc.firstChild!.isTextblock && doc.firstChild!.content.size === 0
}

const isEmptyParagraph = (node: JSONContent) => node.type === 'paragraph' && !node.content?.length

const isBlank = (value: unknown) => value === null || value === undefined || value === ''

/**
 * A rich-text editor built on Tiptap's StarterKit, with a toolbar. Stores HTML, or Tiptap JSON
 * with `@output="json"`; an empty document stores `''` (`null` for JSON).
 */
export class RichTextControl extends Component<RichTextControlSignature> {
  readonly editor: Editor
  /** The value this control last sent or was given, so it isn't set back into the editor. */
  private current: unknown
  /** Bumped after each transaction, so the toolbar's pressed states re-render. */
  @tracked revision = 0

  constructor(owner: Owner, args: RichTextControlSignature['Args']) {
    super(owner, args)
    this.current = args.value
    this.editor = new Editor({
      element: null,
      content: (args.value ?? '') as Content,
      extensions: [StarterKit.configure(args.starterKit), ...(args.extensions ?? [])],
      editorProps: {
        attributes: (state: EditorState) => ({
          class: 'fw-rich-text-editor',
          ...(isEmptyDoc(state) ? { 'data-empty': '' } : {}),
        }),
      },
      onUpdate: () => this.onUpdate(),
      onTransaction: () => this.refresh(),
    })
  }

  get isJson(): boolean {
    return this.args.output === 'json'
  }

  get editable(): boolean {
    return !(this.args.disabled || this.args.readonly)
  }

  /** The toolbar's buttons, in groups; empty groups are left out. */
  get groups(): Tool[][] {
    const wanted = this.args.toolbar
    if (wanted === false) return []
    const names = new Set(wanted ?? DEFAULT_TOOLBAR)
    return GROUPS.map(group =>
      TOOLS.filter(tool => group.includes(tool.name) && names.has(tool.name)),
    ).filter(group => group.length)
  }

  /**
   * What the document stores as. StarterKit keeps an empty paragraph after a final list or
   * heading, so there is somewhere to type; it isn't content, so it isn't stored.
   */
  serialize(): RichTextValue {
    if (this.editor.isEmpty) return this.isJson ? null : ''
    if (!this.isJson) return this.editor.getHTML().replace(/(<p><\/p>)+$/, '')
    const json = this.editor.getJSON()
    const content = [...(json.content ?? [])]
    while (content.length > 1 && isEmptyParagraph(content[content.length - 1]!)) content.pop()
    return { ...json, content }
  }

  onUpdate(): void {
    const value = this.serialize()
    this.current = value
    this.args.onChange(value)
  }

  /** Transactions also happen while rendering (setting content), so re-render after it. */
  refresh(): void {
    queueMicrotask(() => {
      if (!this.isDestroying) this.revision++
    })
  }

  isPressed = (tool: Tool, _revision: number): boolean => tool.isActive(this.editor)
  isDisabled = (tool: Tool, _revision: number): boolean => !this.editable || !tool.can(this.editor)

  run = (tool: Tool): void => tool.run(this.editor)

  /** Keeps the editor's selection when a toolbar button is clicked. */
  keepFocus = (event: MouseEvent): void => event.preventDefault()

  /** Mounts the editor on this element; a click on the field's label focuses it. */
  mount = modifier((element: HTMLElement) => {
    this.editor.mount({ mount: element })
    const label = element.id
      ? document.querySelector<HTMLLabelElement>(`label[for="${CSS.escape(element.id)}"]`)
      : null
    const focus = () => element.focus()
    label?.addEventListener('click', focus)
    return () => {
      label?.removeEventListener('click', focus)
      this.editor.destroy()
    }
  })

  /** A new value from outside (a reset, a rollback) replaces the document, without a change. */
  sync = modifier((_element: HTMLElement, [value]: [unknown]) => {
    if (value === this.current) return
    this.current = value
    if (isBlank(value) && this.editor.isEmpty) return
    const same = this.isJson
      ? JSON.stringify(value) === JSON.stringify(this.serialize())
      : value === this.serialize()
    if (!same) this.editor.commands.setContent((value ?? '') as Content, { emitUpdate: false })
  })

  setEditable = modifier((_element: HTMLElement, [editable]: [boolean]) => {
    if (this.editor.isEditable !== editable) this.editor.setEditable(editable, false)
  })

  /** Enter makes a new paragraph; it doesn't reach the field, which would commit the edit. */
  onKeydown = (event: KeyboardEvent): void => {
    if (event.key === 'Enter') event.stopPropagation()
  }

  <template>
    <div
      class="fw-rich-text{{if @disabled ' fw-rich-text--disabled'}}"
      data-test-fw-control={{@type}}
      data-fw-name={{@name}}
      ...attributes
    >
      {{#if this.groups.length}}
        <div
          class="fw-rich-text-toolbar"
          role="toolbar"
          aria-label="Formatting"
          aria-controls={{@id}}
        >
          {{#each this.groups as |group|}}
            <span class="fw-rich-text-group">
              {{#each group as |tool|}}
                <button
                  type="button"
                  class="fw-rich-text-tool fw-rich-text-tool--{{tool.name}}"
                  title={{tool.label}}
                  aria-label={{tool.label}}
                  aria-pressed={{if
                    tool.toggle
                    (if (this.isPressed tool this.revision) "true" "false")
                  }}
                  disabled={{this.isDisabled tool this.revision}}
                  data-test-fw-tool={{tool.name}}
                  {{on "mousedown" this.keepFocus}}
                  {{on "click" (fn this.run tool)}}
                >
                  <ToolIcon @name={{tool.name}} />
                </button>
              {{/each}}
            </span>
          {{/each}}
        </div>
      {{/if}}
      <div
        id={{@id}}
        aria-multiline="true"
        aria-label={{@label}}
        aria-describedby={{@describedBy}}
        aria-invalid={{if @invalid "true"}}
        aria-required={{if @required "true"}}
        aria-readonly={{if @readonly "true"}}
        aria-disabled={{if @disabled "true"}}
        aria-placeholder={{@placeholder}}
        data-placeholder={{@placeholder}}
        {{this.mount}}
        {{this.sync @value}}
        {{this.setEditable this.editable}}
        {{on "keydown" this.onKeydown}}
      ></div>
    </div>
  </template>
}

/** Each button's glyph: a letter for marks, a small SVG for the rest. Decorative. */
const ToolIcon: TOC<{ Args: { name: RichTextTool } }> = <template>
  {{#if (eq @name "bold")}}<b aria-hidden="true">B</b>
  {{else if (eq @name "italic")}}<i aria-hidden="true">I</i>
  {{else if (eq @name "strike")}}<s aria-hidden="true">S</s>
  {{else}}
    <svg
      aria-hidden="true"
      viewBox="0 0 16 16"
      width="16"
      height="16"
      fill="none"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    >
      {{#if (eq @name "heading-2")}}
        <path d="M2 3.5v9M8 3.5v9M2 8h6" />
        <path d="M10.5 9.2c0-.7.6-1.2 1.3-1.2s1.3.5 1.3 1.2c0 1-2.6 1.8-2.6 3.3h2.8" />
      {{else if (eq @name "heading-3")}}
        <path d="M2 3.5v9M8 3.5v9M2 8h6" />
        <path d="M10.6 8h2.4l-1.4 1.6c.9 0 1.5.5 1.5 1.3s-.7 1.4-1.5 1.4c-.6 0-1.1-.3-1.3-.7" />
      {{else if (eq @name "bullet-list")}}
        <circle cx="2.5" cy="4" r="1" fill="currentColor" stroke="none" />
        <circle cx="2.5" cy="8" r="1" fill="currentColor" stroke="none" />
        <circle cx="2.5" cy="12" r="1" fill="currentColor" stroke="none" />
        <path d="M6 4h8M6 8h8M6 12h8" />
      {{else if (eq @name "ordered-list")}}
        <path d="M2 2.5h1v3M2 5.5h2M2 9.5c0-.6.5-1 1-1s1 .4 1 1c0 .8-2 1.5-2 2.5h2" />
        <path d="M7 4h7M7 8h7M7 12h7" />
      {{else if (eq @name "blockquote")}}
        <path d="M3 3v10M7 5h7M7 8h7M7 11h5" />
      {{else if (eq @name "undo")}}
        <path d="M4 6h6.5a3 3 0 0 1 0 6H7" /><path d="M6.5 3.5 4 6l2.5 2.5" />
      {{else if (eq @name "redo")}}
        <path d="M12 6H5.5a3 3 0 0 0 0 6H9" /><path d="M9.5 3.5 12 6l-2.5 2.5" />
      {{/if}}
    </svg>
  {{/if}}
</template>

function eq(a: unknown, b: unknown): boolean {
  return a === b
}

/**
 * Plain text from a rich-text value (HTML or Tiptap JSON), for the field's `@format` in inline
 * forms: `<f.Field @control="rich-text" @format={{toPlainText}} />`.
 */
export function toPlainText(value: RichTextValue | undefined): string {
  if (isBlank(value)) return ''
  if (typeof value === 'string') {
    // Blocks end in a space, so "<p>a</p><p>b</p>" reads "a b", not "ab".
    const spaced = value.replace(/<\/(p|h[1-6]|li|blockquote|pre)>|<br\s*\/?>/gi, '$& ')
    const text = new DOMParser().parseFromString(spaced, 'text/html').body.textContent ?? ''
    return text.replace(/\s+/g, ' ').trim()
  }
  const words: string[] = []
  const walk = (node: JSONContent) => {
    if (node.text) words.push(node.text)
    node.content?.forEach(walk)
    if (node.type !== 'text') words.push(' ')
  }
  walk(value as JSONContent)
  return words.join('').replace(/\s+/g, ' ').trim()
}

/** Makes `@control="rich-text"` available to every form. Call once, e.g. in app.ts. */
export function registerTiptapControl(name = 'rich-text'): void {
  registerControl(name, RichTextControl)
}
