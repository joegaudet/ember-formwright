import { triggerEvent, click, waitUntil } from '@ember/test-helpers'
import { FieldHarness } from '@ember-formwright/test-support'
import { selectFiles } from 'ember-file-upload/test-support'

/**
 * Drives a `file` or `files` field:
 *
 *   class ApplicationForm extends FormHarness {
 *     @field(FileUploadHarness) declare resume: FileUploadHarness
 *   }
 *
 *   await form.resume.select(new File(['...'], 'cv.pdf', { type: 'application/pdf' }))
 *   assert.deepEqual(form.resume.files, ['cv.pdf'])
 */
export class FileUploadHarness extends FieldHarness {
  static override controls = ['file', 'files']

  /** The native file input the field's label points at. */
  get input(): HTMLInputElement {
    return this.control as HTMLInputElement
  }

  /** The drop zone around the input. */
  get dropzone(): HTMLElement {
    const zone = this.element.querySelector<HTMLElement>('[data-test-fw-dropzone]')
    if (!zone) throw new Error(`Formwright harness: no drop zone in field "${this.path}"`)
    return zone
  }

  /** The names in the file list: stored files, then uploading or failed ones. */
  get files(): string[] {
    return [...this.element.querySelectorAll('[data-test-fw-file]')].map(item =>
      item.getAttribute('data-test-fw-file')!,
    )
  }

  /** Names of the files still uploading. */
  get uploading(): string[] {
    return this.withState('uploading')
  }

  /** Names of the files whose upload failed. */
  get failed(): string[] {
    return this.withState('failed')
  }

  /** The names `@accept` turned away on the last drop. */
  get rejected(): string | undefined {
    return this.element
      .querySelector('[data-test-fw-file-rejected]')
      ?.textContent?.replace(/\s+/g, ' ')
      .trim()
  }

  private withState(state: string): string[] {
    return [...this.element.querySelectorAll(`[data-test-fw-upload-state="${state}"]`)].map(item =>
      item.getAttribute('data-test-fw-file')!,
    )
  }

  /** Chooses files with the file picker. Doesn't wait for `@upload`; see `waitForUploads`. */
  async select(...files: File[]): Promise<void> {
    await selectFiles(this.input, ...files)
  }

  /** Drags files from the desktop and drops them on the drop zone. */
  async drop(...files: File[]): Promise<void> {
    const dataTransfer = {
      files,
      types: ['Files'],
      items: files.map(file => ({ kind: 'file', type: file.type })),
    }
    await triggerEvent(this.dropzone, 'dragenter', { dataTransfer })
    await triggerEvent(this.dropzone, 'dragover', { dataTransfer })
    await triggerEvent(this.dropzone, 'drop', { dataTransfer })
  }

  /** Clicks the remove button of the file with this name. */
  async remove(name: string): Promise<void> {
    const button = this.element.querySelector(`[data-test-fw-remove="${CSS.escape(name)}"]`)
    if (!button) throw new Error(`Formwright harness: no remove button for "${name}"`)
    await click(button)
  }

  /** Clicks Retry on a failed upload. */
  async retry(name: string): Promise<void> {
    const button = this.element.querySelector(`[data-test-fw-retry="${CSS.escape(name)}"]`)
    if (!button) throw new Error(`Formwright harness: no failed upload named "${name}"`)
    await click(button)
  }

  /** Waits until no file is uploading: each has been stored, or has failed. */
  async waitForUploads(): Promise<void> {
    await waitUntil(() => this.uploading.length === 0, {
      timeoutMessage: `Formwright harness: uploads in "${this.path}" never finished`,
    })
  }
}
