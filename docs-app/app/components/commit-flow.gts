import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'

type Mode = 'form' | 'inline'
type Layer = 'warp-drive' | 'changeset'
type Scenario = 'commit' | 'rollback'
type LaneName = 'field' | 'draft' | 'pending' | 'saved'
type Press = 'submit' | 'reset' | 'commit' | 'cancel'

/** Where the value is after a step; a missing lane is empty. */
interface Step {
  action: string
  values: Partial<Record<LaneName, string>>
  /** The lanes a value just moved between, for the arrow. */
  from?: LaneName
  to?: LaneName
  caption: Record<Layer, string>
  /** What the controls show: the field's text, whether an inline field is open, what was pressed. */
  ui: { text: string; editing?: boolean; typing?: boolean; press?: Press }
}

const OLD = 'Ada'
const NEW = 'Grace'

const start: Step = {
  action: 'Start',
  values: { field: OLD, saved: OLD },
  ui: { text: OLD },
  caption: {
    'warp-drive': `The field shows the record's saved name, ${OLD}.`,
    changeset: `The field reads ${OLD} through the changeset, which has no changes yet.`,
  },
}

const write = (from: LaneName): Step => ({
  action: from === 'draft' ? 'Commit (✓ or Enter)' : `Type “${NEW}”`,
  values: { field: NEW, pending: NEW, saved: OLD },
  from,
  to: 'pending',
  ui: from === 'draft' ? { text: NEW, press: 'commit' } : { text: NEW, typing: true },
  caption: {
    'warp-drive': `The adapter writes record.name = '${NEW}'. The record is dirty, and anything else showing it already sees ${NEW}.`,
    changeset: `The adapter writes changeset.set('name', '${NEW}'). The model underneath still says ${OLD}.`,
  },
})

const draft: Step = {
  action: `Click ${OLD}, type “${NEW}”`,
  values: { field: NEW, draft: NEW, saved: OLD },
  from: 'field',
  to: 'draft',
  ui: { text: NEW, editing: true, typing: true },
  caption: {
    'warp-drive': `Inline, the field keeps its own draft. Nothing reaches the record until you commit.`,
    changeset: `Inline, the field keeps its own draft. Nothing reaches the changeset until you commit.`,
  },
}

const save = (action: string): Step => ({
  action,
  values: { field: NEW, saved: NEW },
  from: 'pending',
  to: 'saved',
  ui: { text: NEW, press: 'submit' },
  caption: {
    'warp-drive': `The form validates, then calls record.save(). The server has ${NEW}, and the record is clean.`,
    changeset: `The form validates, then calls changeset.save(): it applies ${NEW} to the model and saves the model.`,
  },
})

const reset: Step = {
  action: 'Reset',
  values: { field: OLD, saved: OLD },
  from: 'pending',
  to: 'field',
  ui: { text: OLD, press: 'reset' },
  caption: {
    'warp-drive': `Reset calls record.rollbackAttributes(): every attribute goes back to its last saved value.`,
    changeset: `Reset calls changeset.rollback(): the pending change is dropped. The model never saw it.`,
  },
}

const cancel: Step = {
  action: 'Cancel (✕ or Esc)',
  values: { field: OLD, saved: OLD },
  from: 'draft',
  to: 'field',
  ui: { text: OLD, press: 'cancel' },
  caption: {
    'warp-drive': `Cancel drops the draft; the record never saw it. After a commit, Reset rolls the record back as in a form.`,
    changeset: `Cancel drops the draft; the changeset never saw it. After a commit, Reset rolls the changeset back as in a form.`,
  },
}

const STEPS: Record<Mode, Record<Scenario, Step[]>> = {
  form: {
    commit: [start, write('field'), save('Submit')],
    rollback: [start, write('field'), reset],
  },
  inline: {
    commit: [start, draft, write('draft'), save('Submit (or @autoSubmit)')],
    rollback: [start, draft, cancel],
  },
}

const LANES: Record<Layer, Record<'pending' | 'saved', string>> = {
  'warp-drive': { pending: 'Record (unsaved)', saved: 'Server' },
  changeset: { pending: 'Changeset', saved: 'Model' },
}

const PLAY_EVERY_MS = 2000

const eq = (a: unknown, b: unknown) => a === b
/** One item keyed by step, so the chip is re-created (and re-animated) on every step. */
const keyed = (key: string) => [key]

/**
 * An animated walk through what commit and rollback do to a value, in a form or inline, with
 * a WarpDrive record or an ember-changeset changeset as the model.
 */
export class CommitFlow extends Component {
  @tracked mode: Mode = 'form'
  @tracked layer: Layer = 'warp-drive'
  @tracked scenario: Scenario = 'commit'
  @tracked index = 0
  timer?: ReturnType<typeof setTimeout>

  get steps(): Step[] {
    return STEPS[this.mode][this.scenario]
  }

  get step(): Step {
    return this.steps[this.index]!
  }

  get lanes() {
    const step = this.step
    const names: LaneName[] =
      this.mode === 'inline'
        ? ['field', 'draft', 'pending', 'saved']
        : ['field', 'pending', 'saved']
    const labels: Record<LaneName, string> = {
      field: 'Field',
      draft: 'Inline draft',
      ...LANES[this.layer],
    }
    return names.map((name, i) => {
      const next = names[i + 1]
      const forward = step.from === name && step.to === next
      const back = step.to === name && step.from === next
      return {
        name,
        label: labels[name],
        value: step.values[name],
        key: `${this.mode}-${this.scenario}-${this.index}`,
        active: step.from === name || step.to === name,
        arrow: next === undefined ? null : forward ? 'forward' : back ? 'back' : 'idle',
      }
    })
  }

  get ui() {
    const { text, editing, typing, press } = this.step.ui
    const inline = this.mode === 'inline'
    return {
      text,
      typing,
      inline,
      // A form's field is always an input; an inline field only while it's open.
      editing: !inline || Boolean(editing),
      submit: press === 'submit',
      reset: press === 'reset',
      // Commit and cancel close the inline editor; a badge shows which one was pressed.
      pressed: press === 'commit' ? '✓' : press === 'cancel' ? '✕' : null,
      key: `${this.mode}-${this.scenario}-${this.index}`,
    }
  }

  get caption(): string {
    return this.step.caption[this.layer]
  }

  get position(): string {
    return `Step ${this.index + 1} of ${this.steps.length}: ${this.step.action}`
  }

  get isFirst(): boolean {
    return this.index === 0
  }

  get isLast(): boolean {
    return this.index === this.steps.length - 1
  }

  setMode = (mode: Mode) => {
    this.mode = mode
    this.restart()
  }

  setLayer = (layer: Layer) => {
    this.layer = layer
    this.restart()
  }

  setScenario = (scenario: Scenario) => {
    this.scenario = scenario
    this.restart()
  }

  restart() {
    this.stop()
    this.index = 0
  }

  next = () => {
    this.stop()
    if (!this.isLast) this.index++
  }

  back = () => {
    this.stop()
    if (!this.isFirst) this.index--
  }

  play = () => {
    this.stop()
    this.index = 0
    const tick = () => {
      if (this.isLast) return this.stop()
      this.index++
      this.timer = setTimeout(tick, PLAY_EVERY_MS)
    }
    this.timer = setTimeout(tick, PLAY_EVERY_MS / 2)
  }

  stop() {
    clearTimeout(this.timer)
    this.timer = undefined
  }

  willDestroy() {
    super.willDestroy()
    this.stop()
  }

  <template>
    <figure class="flow">
      <div class="flow-controls">
        <div class="flow-toggle" role="group" aria-label="Mode">
          <button
            type="button"
            aria-pressed={{if (eq this.mode "form") "true" "false"}}
            data-test-flow-mode="form"
            {{on "click" (fn this.setMode "form")}}
          >Form</button>
          <button
            type="button"
            aria-pressed={{if (eq this.mode "inline") "true" "false"}}
            data-test-flow-mode="inline"
            {{on "click" (fn this.setMode "inline")}}
          >Inline</button>
        </div>
        <div class="flow-toggle" role="group" aria-label="Data layer">
          <button
            type="button"
            aria-pressed={{if (eq this.layer "warp-drive") "true" "false"}}
            data-test-flow-layer="warp-drive"
            {{on "click" (fn this.setLayer "warp-drive")}}
          >WarpDrive</button>
          <button
            type="button"
            aria-pressed={{if (eq this.layer "changeset") "true" "false"}}
            data-test-flow-layer="changeset"
            {{on "click" (fn this.setLayer "changeset")}}
          >ember-changeset</button>
        </div>
        <div class="flow-toggle" role="group" aria-label="Scenario">
          <button
            type="button"
            aria-pressed={{if (eq this.scenario "commit") "true" "false"}}
            data-test-flow-scenario="commit"
            {{on "click" (fn this.setScenario "commit")}}
          >Commit</button>
          <button
            type="button"
            aria-pressed={{if (eq this.scenario "rollback") "true" "false"}}
            data-test-flow-scenario="rollback"
            {{on "click" (fn this.setScenario "rollback")}}
          >Roll back</button>
        </div>
      </div>

      {{! A drawing of the form's controls; the caption says the same thing in words. }}
      <div class="flow-ui" aria-hidden="true">
        <span class="flow-ui-label">Name</span>
        {{#each (keyed this.ui.key) key="@identity"}}
          {{#if this.ui.editing}}
            <span class="flow-ui-input" data-test-flow-ui-input>
              <span class={{if this.ui.typing "flow-typed"}}>{{this.ui.text}}</span>
            </span>
            {{#if this.ui.inline}}
              <span class="flow-ui-button" data-test-flow-ui-commit>✓</span>
              <span class="flow-ui-button" data-test-flow-ui-cancel>✕</span>
            {{/if}}
          {{else}}
            <span class="flow-ui-display" data-test-flow-ui-display>{{this.ui.text}}</span>
            {{#if this.ui.pressed}}
              <span
                class="flow-ui-button is-pressed"
                data-test-flow-ui-pressed
              >{{this.ui.pressed}}</span>
            {{/if}}
          {{/if}}
        {{/each}}
        <span class="flow-ui-actions">
          <span
            class="flow-ui-button is-primary {{if this.ui.submit 'is-pressed'}}"
            data-test-flow-ui-submit
          >Submit</span>
          <span
            class="flow-ui-button {{if this.ui.reset 'is-pressed'}}"
            data-test-flow-ui-reset
          >Reset</span>
        </span>
      </div>

      <ol class="flow-lanes" aria-label="Where the value is">
        {{#each this.lanes as |lane|}}
          <li class="flow-lane {{if lane.active 'is-active'}}" data-test-flow-lane={{lane.name}}>
            <span class="flow-lane-label">{{lane.label}}</span>
            {{#each (keyed lane.key) key="@identity"}}
              {{#if lane.value}}
                <span class="flow-chip" data-test-flow-value>{{lane.value}}</span>
              {{else}}
                <span class="flow-empty">empty</span>
              {{/if}}
            {{/each}}
          </li>
          {{#if lane.arrow}}
            <li class="flow-arrow is-{{lane.arrow}}" aria-hidden="true"></li>
          {{/if}}
        {{/each}}
      </ol>

      <figcaption class="flow-caption" aria-live="polite" data-test-flow-caption>
        <strong>{{this.position}}.</strong>
        {{this.caption}}
      </figcaption>

      <div class="flow-steps">
        <button type="button" data-test-flow-play {{on "click" this.play}}>Play</button>
        <button
          type="button"
          disabled={{this.isFirst}}
          data-test-flow-back
          {{on "click" this.back}}
        >Back</button>
        <button
          type="button"
          disabled={{this.isLast}}
          data-test-flow-next
          {{on "click" this.next}}
        >Next</button>
      </div>
    </figure>
  </template>
}
