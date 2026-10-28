import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import PowerSelect, { type PowerSelectArgs } from 'ember-power-select/components/power-select'
import type { Select } from 'ember-power-select/types'
import {
  registerControl,
  keyOf,
  labelOf,
  matches,
  toStored,
  type ControlSignature,
} from '@ember-formwright/ember'

/** The power-select args a field's `Control` forwards as they are. */
type ForwardedArgs = Pick<
  PowerSelectArgs<unknown, boolean>,
  | 'afterOptionsComponent'
  | 'allowClear'
  | 'animationEnabled'
  | 'beforeOptionsComponent'
  | 'buildSelection'
  | 'calculatePosition'
  | 'closeOnSelect'
  | 'defaultHighlighted'
  | 'destination'
  | 'dropdownClass'
  | 'extra'
  | 'groupComponent'
  | 'highlightOnHover'
  | 'horizontalPosition'
  | 'initiallyOpened'
  | 'loadingMessage'
  | 'matchTriggerWidth'
  | 'matcher'
  | 'noMatchesMessage'
  | 'onBlur'
  | 'onClose'
  | 'onFocus'
  | 'onInput'
  | 'onOpen'
  | 'optionsComponent'
  | 'placeholderComponent'
  | 'registerAPI'
  | 'renderInPlace'
  | 'resultCountMessage'
  | 'search'
  | 'searchEnabled'
  | 'searchField'
  | 'searchFieldPosition'
  | 'searchMessage'
  | 'searchPlaceholder'
  | 'selectedItemComponent'
  | 'title'
  | 'triggerComponent'
  | 'typeAheadOptionMatcher'
  | 'verticalPosition'
>

type AnySelect = Select<unknown, boolean>

export interface PowerSelectControlSignature {
  /** A wrapper around power-select, carrying the control's hooks and any attributes. */
  Element: HTMLDivElement
  Args: ControlSignature['Args'] &
    ForwardedArgs & {
      /** Runs before the field's own keyboard handling; return false to stop it. */
      onKeydown?: (select: AnySelect, event: KeyboardEvent) => boolean | void | undefined
      /**
       * With `@storeKey` and options from `@search`: the option (or, for a multiple select, the
       * options) the stored key stands for, so the trigger can show it on first render.
       */
      selectedOption?: unknown
    }
  Blocks: {
    /** Renders each option, and the selected one in the trigger. Default: its label. */
    default: [option: unknown, select: AnySelect]
  }
}

function asArray(value: unknown): unknown[] {
  if (Array.isArray(value)) return value
  return value === null || value === undefined ? [] : [value]
}

/**
 * A Formwright control around ember-power-select's `<PowerSelect>`. The field's wiring maps
 * onto power-select's args (`@id` to `@triggerId`, `@invalid` to `@ariaInvalid`, ...); any
 * extra power-select arg given to `field.Control` is forwarded.
 */
export class PowerSelectControl extends Component<PowerSelectControlSignature> {
  /** Options chosen this session, so a stored key from an async search still finds its option. */
  @tracked chosen: readonly unknown[] = []

  get multiple(): boolean {
    return false
  }

  get options(): readonly unknown[] | undefined {
    return this.args.options
  }

  /** Every option the stored value could stand for. */
  get known(): unknown[] {
    return [...(this.args.options ?? []), ...asArray(this.args.selectedOption), ...this.chosen]
  }

  /** The option a stored value (an option, or its key with `@storeKey`) stands for. */
  optionFor = (value: unknown): unknown => {
    const option = this.known.find(o => matches(value, o, this.args.optionKey))
    if (option !== undefined) return option
    // A stored key with nothing to map it to: show nothing rather than the bare key.
    return this.args.storeKey ? undefined : value
  }

  get selected(): unknown {
    if (this.multiple) {
      return asArray(this.args.value)
        .map(this.optionFor)
        .filter(o => o !== undefined)
    }
    const value = this.args.value
    return value === null || value === undefined ? undefined : this.optionFor(value)
  }

  get disabled(): boolean {
    // power-select has no readonly state; like the built-in select, readonly disables it.
    return Boolean(this.args.disabled || this.args.readonly)
  }

  /** Inside a callout the dropdown must stay inside the popover (the top layer). */
  get renderInPlace(): boolean | undefined {
    return this.args.callout ? true : this.args.renderInPlace
  }

  /**
   * Searches by each option's label (`@optionLabel`, else `label` or `name`), unless power-select
   * is told what to match with `@matcher` or `@searchField`.
   */
  get matcher(): ((option: unknown, text: string) => number) | undefined {
    if (this.args.matcher || this.args.searchField) return this.args.matcher
    return (option, text) =>
      this.labelFor(option).toLocaleLowerCase().indexOf(text.toLocaleLowerCase())
  }

  labelFor = (option: unknown): string => labelOf(option, this.args.optionLabel)
  keyFor = (option: unknown): string => String(keyOf(option, this.args.optionKey))

  onChange = (selection: unknown): void => {
    const store = (option: unknown) => toStored(option, this.args.storeKey, this.args.optionKey)
    if (this.multiple) {
      const options = asArray(selection)
      this.remember(options)
      this.args.onChange(options.map(store))
    } else if (selection === null || selection === undefined) {
      this.args.onChange(null)
    } else {
      this.remember([selection])
      this.args.onChange(store(selection))
    }
  }

  remember(options: unknown[]): void {
    if (!this.args.storeKey) return
    const known = this.known
    const fresh = options.filter(o => !known.includes(o))
    if (fresh.length) this.chosen = [...this.chosen, ...fresh]
  }

  /**
   * While the dropdown is open, Enter and Escape belong to it: they choose an option or close
   * the dropdown, and don't reach the field, which would commit or cancel the edit.
   */
  onKeydown = (select: AnySelect, event: KeyboardEvent): boolean | void => {
    if (this.args.onKeydown?.(select, event) === false) return false
    if (select.isOpen && (event.key === 'Enter' || event.key === 'Escape')) event.stopPropagation()
  }

  <template>
    <div
      class="fw-power-select-control"
      data-test-fw-control={{@type}}
      data-fw-name={{@name}}
      ...attributes
    >
      <PowerSelect
        @options={{this.options}}
        @selected={{this.selected}}
        @multiple={{this.multiple}}
        @onChange={{this.onChange}}
        @onKeydown={{this.onKeydown}}
        @triggerId={{@id}}
        @triggerClass="fw-control fw-power-select"
        @dropdownClass={{@dropdownClass}}
        @ariaLabel={{@label}}
        @ariaDescribedBy={{@describedBy}}
        @ariaInvalid={{if @invalid "true"}}
        @required={{if @required "true"}}
        @disabled={{this.disabled}}
        @placeholder={{@placeholder}}
        @renderInPlace={{this.renderInPlace}}
        @afterOptionsComponent={{@afterOptionsComponent}}
        @allowClear={{@allowClear}}
        @animationEnabled={{@animationEnabled}}
        @beforeOptionsComponent={{@beforeOptionsComponent}}
        @buildSelection={{@buildSelection}}
        @calculatePosition={{@calculatePosition}}
        @closeOnSelect={{@closeOnSelect}}
        @defaultHighlighted={{@defaultHighlighted}}
        @destination={{@destination}}
        @extra={{@extra}}
        @groupComponent={{@groupComponent}}
        @highlightOnHover={{@highlightOnHover}}
        @horizontalPosition={{@horizontalPosition}}
        @initiallyOpened={{@initiallyOpened}}
        @loadingMessage={{@loadingMessage}}
        @matchTriggerWidth={{@matchTriggerWidth}}
        @matcher={{this.matcher}}
        @noMatchesMessage={{@noMatchesMessage}}
        @onBlur={{@onBlur}}
        @onClose={{@onClose}}
        @onFocus={{@onFocus}}
        @onInput={{@onInput}}
        @onOpen={{@onOpen}}
        @optionsComponent={{@optionsComponent}}
        @placeholderComponent={{@placeholderComponent}}
        @registerAPI={{@registerAPI}}
        @resultCountMessage={{@resultCountMessage}}
        @search={{@search}}
        @searchEnabled={{@searchEnabled}}
        @searchField={{@searchField}}
        @searchFieldPosition={{@searchFieldPosition}}
        @searchMessage={{@searchMessage}}
        @searchPlaceholder={{@searchPlaceholder}}
        @selectedItemComponent={{@selectedItemComponent}}
        @title={{@title}}
        @triggerComponent={{@triggerComponent}}
        @typeAheadOptionMatcher={{@typeAheadOptionMatcher}}
        @verticalPosition={{@verticalPosition}}
        as |option select|
      >
        <span class="fw-power-select-option" data-test-fw-option={{this.keyFor option}}>
          {{#if (has-block)}}
            {{yield option select}}
          {{else}}
            {{this.labelFor option}}
          {{/if}}
        </span>
      </PowerSelect>
    </div>
  </template>
}

/** The same control, storing an array: of options, or of their keys with `@storeKey`. */
export class PowerSelectMultipleControl extends PowerSelectControl {
  override get multiple(): boolean {
    return true
  }
}

/**
 * Makes `@control="power-select"` and `@control="power-select-multiple"` available to every
 * form. Call once, e.g. in app.ts.
 */
export function registerPowerSelectControls({
  single = 'power-select',
  multiple = 'power-select-multiple',
}: { single?: string; multiple?: string } = {}): void {
  registerControl(single, PowerSelectControl)
  registerControl(multiple, PowerSelectMultipleControl)
}
