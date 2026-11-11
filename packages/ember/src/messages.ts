import type { Message } from './i18n.ts'

/** Every built-in string of @ember-formwright/ember, for translation catalogs. */
export const messages = {
  submit: { id: 'formwright.form.submit', message: 'Submit', description: 'The submit button' },
  reset: {
    id: 'formwright.form.reset',
    message: 'Reset',
    description: 'The button that discards unsaved changes',
  },
  apply: {
    id: 'formwright.field.apply',
    message: 'Apply',
    description: 'Accessible name of the button that applies a pending field change',
  },
  cancel: {
    id: 'formwright.field.cancel',
    message: 'Cancel',
    description: 'Accessible name of the button that discards a pending field change',
  },
} satisfies Record<string, Message>
