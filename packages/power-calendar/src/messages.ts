import type { Message } from '@ember-formwright/ember'

/** Every built-in string of @ember-formwright/power-calendar, for translation catalogs. */
export const messages = {
  trigger: {
    id: 'formwright.datePicker.trigger',
    message: '{label}: {value}',
    description:
      "Accessible name of the date picker's button: the field's label, then the date it shows (or its placeholder)",
  },
} satisfies Record<string, Message>
