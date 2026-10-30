# @ember-formwright/tiptap

## 1.3.0

### Minor Changes

- 5db314e: New package: a `rich-text` control on Tiptap 3's StarterKit. `registerTiptapControl()`
  registers it. It has a toolbar (bold, italic, strikethrough, headings, lists, quote, undo,
  redo; pick with `@toolbar`), stores HTML or, with `@output="json"`, Tiptap JSON, and
  `toPlainText` formats either for inline forms. `RichTextHarness` lives at
  `@ember-formwright/tiptap/test-support`, and `theme.css` follows the Formwright theme.

### Patch Changes

- Updated dependencies [aad9026]
- Updated dependencies [abc6560]
  - @ember-formwright/ember@1.3.0
  - @ember-formwright/test-support@1.3.0
