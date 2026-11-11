import type { Message } from '@ember-formwright/ember'

/** Every built-in string of @ember-formwright/tiptap, for translation catalogs. */
export const messages = {
  toolbar: {
    id: 'formwright.richText.toolbar',
    message: 'Formatting',
    description: "Accessible name of the rich-text editor's toolbar",
  },
  bold: { id: 'formwright.richText.bold', message: 'Bold', description: 'Toolbar button' },
  italic: { id: 'formwright.richText.italic', message: 'Italic', description: 'Toolbar button' },
  strike: {
    id: 'formwright.richText.strike',
    message: 'Strikethrough',
    description: 'Toolbar button',
  },
  heading: {
    id: 'formwright.richText.heading',
    message: 'Heading {level}',
    description: 'Toolbar button; {level} is 2 or 3',
  },
  bulletList: {
    id: 'formwright.richText.bulletList',
    message: 'Bulleted list',
    description: 'Toolbar button',
  },
  orderedList: {
    id: 'formwright.richText.orderedList',
    message: 'Numbered list',
    description: 'Toolbar button',
  },
  blockquote: {
    id: 'formwright.richText.blockquote',
    message: 'Quote',
    description: 'Toolbar button',
  },
  undo: { id: 'formwright.richText.undo', message: 'Undo', description: 'Toolbar button' },
  redo: { id: 'formwright.richText.redo', message: 'Redo', description: 'Toolbar button' },
} satisfies Record<string, Message>
