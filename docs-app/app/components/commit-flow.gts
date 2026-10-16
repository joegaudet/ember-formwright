import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import type { FormStatus } from '@ember-formwright/ember'

type Mode = 'form' | 'inline'
type Layer = 'default' | 'warp-drive' | 'changeset'
type Scenario = 'commit' | 'rollback' | 'invalid' | 'failed'
type LaneName = 'field' | 'draft' | 'pending' | 'saved'
type Press = 'submit' | 'reset' | 'commit' | 'cancel'

/** One moment of the walk-through: where the value is, what the form's status is, what the UI shows. */
interface Step {
  action: string
  /** `f.state.status` after this step. */
  status: FormStatus
  /** Where the value is; a missing lane is empty. */
  values: Partial<Record<LaneName, string>>
  /** The lanes a value just moved between, for the arrow. */
  from?: LaneName
  to?: LaneName
  /** What the drawn controls show. */
  ui: {
    text: string
    editing?: boolean
    typing?: boolean
    press?: Press
    busy?: boolean
    error?: Partial<Record<Layer, string>>
  }
  caption: Record<Layer, string>
}

const OLD = 'Ada'
const NEW = 'Grace'
/** How an empty value shows in a lane. */
const BLANK = '“”'
const REQUIRED = 'Name is required'

const shown = (value: string) => (value === '' ? BLANK : value)
const same = (text: string): Record<Layer, string> => ({
  default: text,
  'warp-drive': text,
  changeset: text,
})

const start: Step = {
  action: 'Start',
  status: 'clean',
  values: { field: OLD, saved: OLD },
  ui: { text: OLD },
  caption: {
    default: `The field reads ${OLD} from the model, and the form records it as the field's baseline.`,
    'warp-drive': `The field reads the record's saved name, ${OLD}, and records it as its baseline.`,
    changeset: `The field reads ${OLD} through the changeset, which has no changes yet.`,
  },
}

function writes(value: string): Record<Layer, string> {
  return {
    default: `The adapter writes set(model, 'name', '${value}'). The model changes at once and differs from its baseline, so the form is dirty.`,
    'warp-drive': `The adapter writes record.name = '${value}'. The record is dirty, and anything else showing it already sees the change.`,
    changeset: `The adapter writes changeset.set('name', '${value}'). The model underneath still says ${OLD}; the form is dirty.`,
  }
}

/** A form field writes through the adapter as you type. */
const type = (value: string): Step => ({
  action: `Type “${value}”`,
  status: 'dirty',
  values: { field: shown(value), pending: shown(value), saved: OLD },
  from: 'field',
  to: 'pending',
  ui: { text: value, typing: true },
  caption: writes(value),
})

/** An inline field keeps its own draft; nothing is written. */
const draft = (value: string): Step => ({
  action: `Click ${OLD}, type “${value}”`,
  status: 'clean',
  values: { field: shown(value), draft: shown(value), saved: OLD },
  from: 'field',
  to: 'draft',
  ui: { text: value, editing: true, typing: true },
  caption: {
    default: `Inline, the field keeps a draft. Nothing reaches the model, so the form is still clean.`,
    'warp-drive': `Inline, the field keeps a draft. Nothing reaches the record, so the form is still clean.`,
    changeset: `Inline, the field keeps a draft. Nothing reaches the changeset, so the form is still clean.`,
  },
})

const commit = (value: string): Step => ({
  action: 'Commit (✓ or Enter)',
  status: 'dirty',
  values: { field: shown(value), pending: shown(value), saved: OLD },
  from: 'draft',
  to: 'pending',
  ui: { text: value, press: 'commit' },
  caption: writes(value),
})

const edit = (mode: Mode, value: string): Step[] =>
  mode === 'inline' ? [draft(value), commit(value)] : [type(value)]

const submitting: Step = {
  action: 'Submit',
  status: 'submitting',
  values: { field: NEW, pending: NEW, saved: OLD },
  from: 'pending',
  to: 'saved',
  ui: { text: NEW, press: 'submit', busy: true },
  caption: {
    default: `Valid, so the form calls model.save() (or @onSubmit). Submit is busy, and a second submit joins this one.`,
    'warp-drive': `Valid, so the form calls record.save(). Submit is busy, and a second submit joins this one.`,
    changeset: `Valid, so the form calls changeset.save(): it applies ${NEW} to the model, then calls model.save().`,
  },
}

const saved: Step = {
  action: 'Saved',
  status: 'clean',
  values: { field: NEW, saved: NEW },
  from: 'pending',
  to: 'saved',
  ui: { text: NEW },
  caption: {
    default: `Saved. The form records ${NEW} as the new baseline, so it is clean again.`,
    'warp-drive': `Saved. The server has ${NEW}, the record is clean, and so is the form.`,
    changeset: `Saved. The model says ${NEW}, the changeset is empty again, and the form is clean.`,
  },
}

const failed: Step = {
  action: 'The save fails',
  status: 'dirty',
  values: { field: NEW, pending: NEW, saved: OLD },
  from: 'saved',
  to: 'pending',
  ui: { text: NEW, error: { 'warp-drive': 'Name is taken' } },
  caption: {
    default: `The save rejects. The model still holds ${NEW} and the baseline is still ${OLD}, so the form stays dirty: retry, or Reset.`,
    'warp-drive': `The save rejects with a 422. record.errors shows on the field, and the record keeps ${NEW} until you retry or Reset.`,
    changeset: `The save rejects. The adapter puts ${OLD} back on the model, and ${NEW} stays in the changeset to retry or Reset.`,
  },
}

const invalid: Step = {
  action: 'Submit',
  status: 'invalid',
  values: { field: BLANK, pending: BLANK, saved: OLD },
  ui: { text: '', press: 'submit', error: same(REQUIRED) },
  caption: {
    default: `Submit runs the @validator first. It fails, so nothing saves: the error shows on its field, which gets focus.`,
    'warp-drive': `Submit runs the @validator before record.save(). It fails, so nothing reaches the server.`,
    changeset: `Submit runs changesetValidator, and changeset.validate() fails, so changeset.save() never runs.`,
  },
}

/** Fixing the value after a failed submit: the form re-validates on every change. */
const fix = (mode: Mode): Step[] => {
  const steps = edit(mode, NEW)
  const last = steps[steps.length - 1]!
  steps[steps.length - 1] = {
    ...last,
    caption: same(
      `After a failed submit the form re-validates on every change. ${NEW} is valid, so the error clears and the form is dirty again.`,
    ),
  }
  return steps
}

const reset: Step = {
  action: 'Reset',
  status: 'clean',
  values: { field: OLD, saved: OLD },
  from: 'pending',
  to: 'field',
  ui: { text: OLD, press: 'reset' },
  caption: {
    default: `Native rollback: the form writes each field's baseline, ${OLD}, back to the model with set(). No data layer needed.`,
    'warp-drive': `Reset calls record.rollbackAttributes(): every attribute goes back to its last saved value.`,
    changeset: `Reset calls changeset.rollback(): the pending change is dropped. The model never saw it.`,
  },
}

const cancel: Step = {
  action: 'Cancel (✕ or Esc)',
  status: 'clean',
  values: { field: OLD, saved: OLD },
  from: 'draft',
  to: 'field',
  ui: { text: OLD, press: 'cancel' },
  caption: same(`Cancel drops the draft before anything is written. The form never left clean.`),
}

function stepsFor(mode: Mode, scenario: Scenario): Step[] {
  switch (scenario) {
    case 'commit':
      return [start, ...edit(mode, NEW), submitting, saved]
    case 'rollback':
      return mode === 'inline'
        ? [start, draft(NEW), cancel, ...edit(mode, NEW), reset]
        : [start, type(NEW), reset]
    case 'invalid':
      return [start, ...edit(mode, ''), invalid, ...fix(mode), submitting, saved]
    case 'failed':
      return [start, ...edit(mode, NEW), submitting, failed]
  }
}

const LANES: Record<Layer, Record<'pending' | 'saved', string>> = {
  default: { pending: 'Model', saved: 'Baseline (last save)' },
  'warp-drive': { pending: 'Record (unsaved)', saved: 'Server' },
  changeset: { pending: 'Changeset', saved: 'Model' },
}

const STATES: { status: FormStatus; label: string }[] = [
  { status: 'clean', label: 'Clean' },
  { status: 'dirty', label: 'Dirty' },
  { status: 'invalid', label: 'Invalid' },
  { status: 'submitting', label: 'Submitting' },
]

const PLAY_EVERY_MS = 2200

const eq = (a: unknown, b: unknown) => a === b
/** One item keyed by step, so its element is re-created (and re-animated) on every step. */
const keyed = (key: string) => [key]

/**
 * An animated walk through the form's state machine: what each step does to the value and to
 * `f.state.status`, in a form or inline, with the default adapter, a WarpDrive record, or an
 * ember-changeset changeset.
 */
export class CommitFlow extends Component {
  @tracked mode: Mode = 'form'
  @tracked layer: Layer = 'default'
  @tracked scenario: Scenario = 'commit'
  @tracked index = 0
  timer?: ReturnType<typeof setTimeout>

  get steps(): Step[] {
    return stepsFor(this.mode, this.scenario)
  }

  get step(): Step {
    return this.steps[this.index]!
  }

  get key(): string {
    return `${this.mode}-${this.layer}-${this.scenario}-${this.index}`
  }

  get states() {
    return STATES.map(state => ({ ...state, current: state.status === this.step.status }))
  }

  /** The `f.state` flags behind the status. */
  get flags(): string {
    const { status } = this.step
    return `isDirty: ${status !== 'clean'} · isValid: ${status !== 'invalid'} · isSubmitting: ${status === 'submitting'}`
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
        // By default the "pending" lane is the model itself, so it always holds a value.
        value:
          this.layer === 'default' && name === 'pending'
            ? (step.values.pending ?? step.values.saved)
            : step.values[name],
        active: step.from === name || step.to === name,
        arrow: next === undefined ? null : forward ? 'forward' : back ? 'back' : 'idle',
      }
    })
  }

  get ui() {
    const { text, editing, typing, press, busy, error } = this.step.ui
    const inline = this.mode === 'inline'
    return {
      text,
      typing,
      busy,
      inline,
      error: error?.[this.layer],
      // A form's field is always an input; an inline field only while it's open, or invalid.
      editing: !inline || Boolean(editing) || this.step.status === 'invalid',
      submit: press === 'submit',
      reset: press === 'reset',
      // Commit and cancel close the inline editor; a badge shows which one was pressed.
      pressed: press === 'commit' ? '✓' : press === 'cancel' ? '✕' : null,
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
        <div class="flow-toggle" role="group" aria-label="Data layer">
          <button
            type="button"
            aria-pressed={{if (eq this.layer "default") "true" "false"}}
            data-test-flow-layer="default"
            {{on "click" (fn this.setLayer "default")}}
          >Default</button>
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
        <div class="flow-toggle" role="group" aria-label="Scenario">
          <button
            type="button"
            aria-pressed={{if (eq this.scenario "commit") "true" "false"}}
            data-test-flow-scenario="commit"
            {{on "click" (fn this.setScenario "commit")}}
          >Save</button>
          <button
            type="button"
            aria-pressed={{if (eq this.scenario "rollback") "true" "false"}}
            data-test-flow-scenario="rollback"
            {{on "click" (fn this.setScenario "rollback")}}
          >Roll back</button>
          <button
            type="button"
            aria-pressed={{if (eq this.scenario "invalid") "true" "false"}}
            data-test-flow-scenario="invalid"
            {{on "click" (fn this.setScenario "invalid")}}
          >Invalid</button>
          <button
            type="button"
            aria-pressed={{if (eq this.scenario "failed") "true" "false"}}
            data-test-flow-scenario="failed"
            {{on "click" (fn this.setScenario "failed")}}
          >Save fails</button>
        </div>
      </div>

      {{! A drawing of the form's controls; the caption says the same thing in words. }}
      <div class="flow-ui" aria-hidden="true">
        <span class="flow-ui-label">Name</span>
        {{#each (keyed this.key) key="@identity"}}
          {{#if this.ui.editing}}
            <span
              class="flow-ui-input {{if this.ui.error 'is-invalid'}}"
              data-test-flow-ui-input
            ><span class={{if this.ui.typing "flow-typed"}}>{{this.ui.text}}</span></span>
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
          <span class="flow-ui-actions">
            <span
              class="flow-ui-button is-primary {{if this.ui.submit 'is-pressed'}}"
              data-test-flow-ui-submit
            >{{if this.ui.busy "Saving…" "Submit"}}</span>
            <span
              class="flow-ui-button {{if this.ui.reset 'is-pressed'}}"
              data-test-flow-ui-reset
            >Reset</span>
          </span>
          {{#if this.ui.error}}
            <span class="flow-ui-error" data-test-flow-ui-error>{{this.ui.error}}</span>
          {{/if}}
        {{/each}}
      </div>

      <div class="flow-machine">
        <ol class="flow-states" aria-label="The form's status">
          {{#each this.states as |state|}}
            <li
              class="flow-state is-{{state.status}}"
              aria-current={{if state.current "step"}}
              data-test-flow-state={{state.status}}
            >{{state.label}}</li>
          {{/each}}
        </ol>
        <code class="flow-status" data-test-flow-status>
          f.state.status: '{{this.step.status}}' ·
          {{this.flags}}
        </code>
      </div>

      <ol class="flow-lanes" aria-label="Where the value is">
        {{#each this.lanes as |lane|}}
          <li class="flow-lane {{if lane.active 'is-active'}}" data-test-flow-lane={{lane.name}}>
            <span class="flow-lane-label">{{lane.label}}</span>
            {{#each (keyed this.key) key="@identity"}}
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
