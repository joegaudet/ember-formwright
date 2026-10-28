import Component from '@glimmer/component'
import type Owner from '@ember/owner'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { fn } from '@ember/helper'
import { service } from '@ember/service'
import { associateDestroyableChild } from '@ember/destroyable'
import { guidFor } from '@ember/object/internals'
import FileDropzone from 'ember-file-upload/components/file-dropzone'
import type { Queue, UploadFile } from 'ember-file-upload'
import type FileQueueService from 'ember-file-upload/services/file-queue'
import { registerControl, labelOf, type ControlSignature } from '@ember-formwright/ember'

/** Uploads a file the user chose, and resolves with what the field stores (an id, a URL, ...). */
export type UploadFn = (file: UploadFile) => Promise<unknown>

export interface FileUploadControlSignature {
  /** A wrapper around the drop zone and the file list, carrying the control's hooks. */
  Element: HTMLDivElement
  Args: ControlSignature['Args'] & {
    /** The file types to offer, as for `<input accept>`: `.pdf`, `image/*`, `text/csv`, ... */
    accept?: string
    /**
     * Uploads each chosen file straight away; the field stores what it resolves to. Without it,
     * the field stores the `File` itself.
     */
    upload?: UploadFn
    /** The drop zone's call to action. Default "Choose a file" or "Choose files". */
    prompt?: string
  }
}

/** A chosen file that is uploading, or whose upload failed. */
class Upload {
  @tracked failed = false
  @tracked error: string | undefined
  readonly file: UploadFile

  constructor(file: UploadFile) {
    this.file = file
  }
}

interface Item {
  value: unknown
  name: string
  size: string | undefined
  kind: string
}

function asArray(value: unknown): unknown[] {
  if (Array.isArray(value)) return value
  return value === null || value === undefined ? [] : [value]
}

/** Whether `file` matches an `accept` list, as the browser's file picker would filter it. */
export function accepts(file: File, accept: string | undefined): boolean {
  if (!accept?.trim()) return true
  const name = file.name.toLowerCase()
  const type = file.type.toLowerCase()
  return accept.split(',').some(raw => {
    const pattern = raw.trim().toLowerCase()
    if (!pattern) return false
    if (pattern.startsWith('.')) return name.endsWith(pattern)
    if (pattern.endsWith('/*')) return type.startsWith(pattern.slice(0, -1))
    return type === pattern
  })
}

/** "PDF", "PNG", ... from a file name; "FILE" when there is no extension. */
function kindOf(name: string): string {
  const dot = name.lastIndexOf('.')
  return dot > 0 && dot < name.length - 1 ? name.slice(dot + 1, dot + 5).toUpperCase() : 'FILE'
}

const UNITS = ['byte', 'kilobyte', 'megabyte', 'gigabyte'] as const

export function formatSize(bytes: number, locale?: string): string {
  let size = bytes
  let unit = 0
  while (size >= 1000 && unit < UNITS.length - 1) {
    size /= 1000
    unit++
  }
  return new Intl.NumberFormat(locale, {
    style: 'unit',
    unit: UNITS[unit],
    unitDisplay: unit ? 'short' : 'long',
    maximumFractionDigits: unit ? 1 : 0,
  }).format(size)
}

/**
 * A Formwright control for choosing files: a native file input inside an ember-file-upload drop
 * zone, and the list of chosen files with a remove button each. `file` stores one, `files` an
 * array. With `@upload`, each file is uploaded as it is chosen and the field stores the result.
 */
export class FileUploadControl extends Component<FileUploadControlSignature> {
  @service('file-queue') declare fileQueue: FileQueueService

  @tracked uploads: readonly Upload[] = []
  /** Dropped files that `@accept` turned away, so the user knows why nothing happened. */
  @tracked rejected: readonly string[] = []

  readonly queue: Queue

  constructor(owner: Owner, args: FileUploadControlSignature['Args']) {
    super(owner, args)
    // A queue per control, so files never mix with another field's (or the app's own).
    this.queue = this.fileQueue.findOrCreate(`formwright:${guidFor(this)}`)
    associateDestroyableChild(this, this.queue)
  }

  get multiple(): boolean {
    return false
  }

  get locked(): boolean {
    return Boolean(this.args.disabled || this.args.readonly)
  }

  get prompt(): string {
    return this.args.prompt ?? (this.multiple ? 'Choose files' : 'Choose a file')
  }

  get rejectedNames(): string {
    return this.rejected.join(', ')
  }

  get isUploading(): boolean {
    return this.uploads.some(upload => !upload.failed)
  }

  /** What the field stores, as list items: name, size and a short type badge. */
  get items(): Item[] {
    return asArray(this.args.value).map(value => {
      const name = this.nameOf(value)
      const size = (value as { size?: unknown } | null)?.size
      return {
        value,
        name,
        size: typeof size === 'number' ? formatSize(size, this.args.locale) : undefined,
        kind: kindOf(name),
      }
    })
  }

  get hasList(): boolean {
    return this.items.length > 0 || this.uploads.length > 0
  }

  nameOf = (value: unknown): string =>
    value instanceof File ? value.name : labelOf(value, this.args.optionLabel)

  kindOf = kindOf

  sizeOf = (file: UploadFile): string => formatSize(file.size, this.args.locale)

  /** Runs for both the picker and the drop zone: what the queue may take. */
  filter = (file: File, _files: File[], index: number): boolean => {
    if (this.locked) return false
    if (!this.multiple && index > 0) return false
    return accepts(file, this.args.accept)
  }

  onDrop = (files: UploadFile[], transfer: { files: File[] }): void => {
    // The drop zone hands over what passed the filter; tell the user about the rest.
    const taken = new Set(files.map(file => file.file))
    this.rejected = this.locked
      ? []
      : transfer.files
          .filter((file, i) => !taken.has(file) && (this.multiple || i === 0))
          .map(file => file.name)
    this.take(files)
  }

  onSelect = (files: UploadFile[]): void => {
    this.rejected = []
    this.take(files)
  }

  take(files: UploadFile[]): void {
    if (!files.length) return
    const upload = this.args.upload
    if (!upload) {
      for (const file of files) this.queue.remove(file)
      this.store(files.map(file => file.file))
      return
    }
    const fresh = files.map(file => new Upload(file))
    this.uploads = [...this.uploads, ...fresh]
    for (const entry of fresh) void this.send(entry, upload)
  }

  async send(entry: Upload, upload: UploadFn): Promise<void> {
    entry.failed = false
    entry.error = undefined
    try {
      const result = await upload(entry.file)
      if (this.isDestroying) return
      this.uploads = this.uploads.filter(u => u !== entry)
      this.queue.remove(entry.file)
      this.store([result])
    } catch (error) {
      if (this.isDestroying) return
      entry.failed = true
      entry.error = error instanceof Error ? error.message : String(error ?? 'Upload failed')
    }
  }

  store(values: unknown[]): void {
    if (this.multiple) this.args.onChange([...asArray(this.args.value), ...values])
    else this.args.onChange(values[values.length - 1] ?? null)
  }

  remove = (value: unknown): void => {
    if (this.locked) return
    if (this.multiple) this.args.onChange(asArray(this.args.value).filter(v => v !== value))
    else this.args.onChange(null)
  }

  retry = (entry: Upload): void => {
    if (this.args.upload) void this.send(entry, this.args.upload)
  }

  dismiss = (entry: Upload): void => {
    this.uploads = this.uploads.filter(u => u !== entry)
    this.queue.remove(entry.file)
  }

  <template>
    <div
      class="fw-file-control{{if this.multiple ' fw-file-control--multiple'}}"
      data-test-fw-control={{@type}}
      data-fw-name={{@name}}
      data-uploading={{if this.isUploading ""}}
      aria-busy={{if this.isUploading "true"}}
      ...attributes
    >
      <FileDropzone
        class="fw-dropzone"
        @queue={{this.queue}}
        @multiple={{this.multiple}}
        @filter={{this.filter}}
        @onDrop={{this.onDrop}}
        data-test-fw-dropzone
        as |dropzone|
      >
        <div
          class="fw-dropzone-body"
          data-active={{if dropzone.active ""}}
          data-disabled={{if this.locked ""}}
        >
          <input
            id={{@id}}
            class="fw-control fw-file-input"
            type="file"
            name={{@name}}
            accept={{@accept}}
            multiple={{this.multiple}}
            disabled={{this.locked}}
            required={{@required}}
            aria-label={{@label}}
            aria-invalid={{if @invalid "true"}}
            aria-describedby={{@describedBy}}
            {{this.queue.selectFile filter=this.filter onFilesSelected=this.onSelect}}
          />
          {{! A second way to open the picker; the input above is named by the field's label. }}
          <label class="fw-dropzone-label" for={{@id}}>
            <svg
              class="fw-dropzone-icon"
              viewBox="0 0 24 24"
              width="22"
              height="22"
              aria-hidden="true"
            >
              <path
                d="M12 16V4m0 0-4.5 4.5M12 4l4.5 4.5M4 15v3a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-3"
                fill="none"
                stroke="currentColor"
                stroke-width="1.8"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
            </svg>
            <span class="fw-dropzone-text">
              {{#if dropzone.active}}
                <strong>Drop to add</strong>
              {{else}}
                <strong class="fw-dropzone-prompt">{{this.prompt}}</strong>
                {{#if dropzone.supported}}<span> or drop here</span>{{/if}}
              {{/if}}
            </span>
            {{#if @accept}}
              <span class="fw-dropzone-accept">{{@accept}}</span>
            {{/if}}
          </label>
        </div>
      </FileDropzone>

      {{#if this.rejected.length}}
        <p class="fw-file-rejected" role="status" data-test-fw-file-rejected>
          Not an accepted type:
          {{this.rejectedNames}}
        </p>
      {{/if}}

      {{#if this.hasList}}
        <ul class="fw-file-list">
          {{#each this.items as |item|}}
            <li class="fw-file" data-test-fw-file={{item.name}}>
              <span class="fw-file-kind" aria-hidden="true">{{item.kind}}</span>
              <span class="fw-file-name">{{item.name}}</span>
              {{#if item.size}}<span class="fw-file-size">{{item.size}}</span>{{/if}}
              {{#unless this.locked}}
                <button
                  type="button"
                  class="fw-file-remove"
                  aria-label="Remove {{item.name}}"
                  data-test-fw-remove={{item.name}}
                  {{on "click" (fn this.remove item.value)}}
                >×</button>
              {{/unless}}
            </li>
          {{/each}}
          {{#each this.uploads as |upload|}}
            <li
              class="fw-file fw-file--{{if upload.failed 'failed' 'uploading'}}"
              data-test-fw-file={{upload.file.name}}
              data-test-fw-upload-state={{if upload.failed "failed" "uploading"}}
            >
              <span class="fw-file-kind" aria-hidden="true">{{this.kindOf upload.file.name}}</span>
              <span class="fw-file-name">{{upload.file.name}}</span>
              {{#if upload.failed}}
                <span class="fw-file-error" data-test-fw-upload-error>{{upload.error}}</span>
                <button
                  type="button"
                  class="fw-file-retry"
                  data-test-fw-retry={{upload.file.name}}
                  {{on "click" (fn this.retry upload)}}
                >Retry</button>
                <button
                  type="button"
                  class="fw-file-remove"
                  aria-label="Remove {{upload.file.name}}"
                  data-test-fw-remove={{upload.file.name}}
                  {{on "click" (fn this.dismiss upload)}}
                >×</button>
              {{else}}
                <span class="fw-file-size">{{this.sizeOf upload.file}}</span>
                <progress
                  class="fw-file-progress"
                  max="100"
                  value={{upload.file.progress}}
                  aria-label="Uploading {{upload.file.name}}"
                ></progress>
              {{/if}}
            </li>
          {{/each}}
        </ul>
      {{/if}}
    </div>
  </template>
}

/** The same control, storing an array: of `File`s, or of what `@upload` resolves to. */
export class FileUploadMultipleControl extends FileUploadControl {
  override get multiple(): boolean {
    return true
  }
}

/**
 * Makes `@control="file"` and `@control="files"` available to every form. Call once, e.g. in
 * app.ts.
 */
export function registerFileUploadControls({
  single = 'file',
  multiple = 'files',
}: { single?: string; multiple?: string } = {}): void {
  registerControl(single, FileUploadControl)
  registerControl(multiple, FileUploadMultipleControl)
}
