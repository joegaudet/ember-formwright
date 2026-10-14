import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { waitForPromise } from '@ember/test-waiters'

const eq = (a: unknown, b: unknown) => a === b

export type ButtonKind = 'button' | 'submit' | 'reset'

export interface ButtonSignature {
  Element: HTMLButtonElement
  Args: {
    /** Busy state from outside, e.g. the form is submitting. */
    busy?: boolean
    disabled?: boolean
    onClick?: () => unknown
    /** Sets the button type and its data-test-fw-<kind> selector. */
    kind?: ButtonKind
    text?: string
  }
  Blocks: { default: [] }
}

export default class Button extends Component<ButtonSignature> {
  /** Set while a promise returned by @onClick is pending. */
  @tracked acting = false

  get kind(): ButtonKind {
    return this.args.kind ?? 'button'
  }

  get busy() {
    return this.acting || this.args.busy
  }

  is = (kind: ButtonKind) => (this.kind === kind ? '' : undefined)

  onClick = async () => {
    if (this.busy || !this.args.onClick) return
    const result = this.args.onClick()
    // Any thenable (native, RSVP, ...) marks the button busy until it settles.
    if (typeof (result as PromiseLike<unknown> | undefined)?.then === 'function') {
      this.acting = true
      try {
        await waitForPromise(Promise.resolve(result))
      } finally {
        this.acting = false
      }
    }
  }

  <template>
    <button
      type={{if (eq this.kind "submit") "submit" "button"}}
      class="fw-button fw-button--{{this.kind}}"
      disabled={{@disabled}}
      aria-busy={{if this.busy "true"}}
      data-test-fw-submit={{this.is "submit"}}
      data-test-fw-reset={{this.is "reset"}}
      data-test-fw-button={{this.is "button"}}
      ...attributes
      {{on "click" this.onClick}}
    >
      {{#if (has-block)}}{{yield}}{{else}}{{@text}}{{/if}}
    </button>
  </template>
}
