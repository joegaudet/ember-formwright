import { tracked } from '@glimmer/tracking'
import { is, isNot } from '@real-enums/core'
import { Machine, State, region, transition } from '@switchyard-ts/core'

/**
 * Where a form is in its life cycle, as `f.state.status`:
 *
 * - `Clean`: every field matches its baseline (the value it rendered with, or last saved)
 * - `Dirty`: a field differs from its baseline
 * - `Invalid`: a submit failed validation; the form re-validates on every change
 * - `Submitting`: the save is in flight
 *
 * A real-enums enum: ask it `status.isDirty` or `status.isNotSubmitting`, compare it with
 * `FormStatus.Dirty`, or render it, which prints its value (`dirty`).
 */
export class FormStatus extends State {
  static Clean = FormStatus.of('clean')
  static Dirty = FormStatus.of('dirty')
  static Invalid = FormStatus.of('invalid')
  static Submitting = FormStatus.of('submitting')

  @is() declare isClean: boolean
  @is() declare isDirty: boolean
  @is() declare isInvalid: boolean
  @is() declare isSubmitting: boolean
  @isNot() declare isNotClean: boolean
  @isNot() declare isNotDirty: boolean
  @isNot() declare isNotInvalid: boolean
  @isNot() declare isNotSubmitting: boolean
}

/**
 * Where a field is, as `@field.status` in a layout:
 *
 * - `Idle`: showing its value, or a live control that writes straight to the model
 * - `Editing`: its inline editor is open; it may hold a value awaiting ✓ or ✕
 * - `Pending`: it holds a value awaiting ✓ or ✕, outside an inline editor (`@requireConfirm`)
 */
export class FieldStatus extends State {
  static Idle = FieldStatus.of('idle')
  static Editing = FieldStatus.of('editing')
  static Pending = FieldStatus.of('pending')

  @is() declare isIdle: boolean
  @is() declare isEditing: boolean
  @is() declare isPending: boolean
  @isNot() declare isNotIdle: boolean
  @isNot() declare isNotEditing: boolean
  @isNot() declare isNotPending: boolean
}

/** A field's events: the field sends them, and holds the uncommitted value here. */
export class FieldMachine<V = unknown> extends Machine<FieldStatus> {
  @tracked buffer: { value: V } | null = null

  @transition({ to: FieldStatus.Editing })
  edit() {}

  /** Only sent when the field needs a confirm; otherwise a change goes straight to the form. */
  @transition({ from: [FieldStatus.Idle, FieldStatus.Pending], to: FieldStatus.Pending })
  @transition({ from: FieldStatus.Editing })
  change(value: V) {
    this.buffer = { value }
  }

  @transition({ to: FieldStatus.Idle })
  commit() {
    this.buffer = null
  }

  @transition({ to: FieldStatus.Idle })
  cancel() {
    this.buffer = null
  }
}

/** The submit in progress, if any. */
export class Submission extends State {
  static Idle = Submission.of('idle')
  static Validating = Submission.of('validating')
  static Saving = Submission.of('saving')

  @is() declare isSaving: boolean
}

/** Whether a submit failed validation since the last save or reset. */
export class Validity extends State {
  static Unchecked = Validity.of('unchecked')
  static Failed = Validity.of('failed')

  @is() declare isFailed: boolean
}

const anyValidity = [Validity.Unchecked, Validity.Failed]

/**
 * A root form's submit, in two parallel regions: `submission` walks a submit through
 * validating and saving; `validity` remembers a failed validation until the next save or reset,
 * so the form keeps re-validating on change, even across a failed save.
 */
export class FormMachine extends Machine<{ submission: Submission; validity: Validity }> {
  @region(Submission) declare submission: Submission
  @region(Validity) declare validity: Validity

  @transition({ in: 'submission', from: Submission.Idle, to: Submission.Validating })
  submit() {}

  @transition({ in: 'submission', from: Submission.Validating, to: Submission.Idle })
  @transition({ in: 'validity', from: anyValidity, to: Validity.Failed })
  invalid() {}

  /** `@willSubmit` said no. */
  @transition({ in: 'submission', from: Submission.Validating, to: Submission.Idle })
  cancel() {}

  @transition({ in: 'submission', from: Submission.Validating, to: Submission.Saving })
  save() {}

  @transition({ in: 'submission', from: Submission.Saving, to: Submission.Idle })
  @transition({ in: 'validity', from: anyValidity, to: Validity.Unchecked })
  saved() {}

  @transition({ in: 'submission', from: Submission.Saving, to: Submission.Idle })
  failed() {}

  /** A reset clears a failed validation; a save in flight carries on. */
  @transition({ in: 'validity', from: anyValidity, to: Validity.Unchecked })
  reset() {}
}
