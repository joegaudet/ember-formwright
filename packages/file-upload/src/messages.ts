import type { Message } from '@ember-formwright/ember'

/** Every built-in string of @ember-formwright/file-upload, for translation catalogs. */
export const messages = {
  chooseFile: {
    id: 'formwright.fileUpload.chooseFile',
    message: 'Choose a file',
    description: "The drop zone's call to action, for one file",
  },
  chooseFiles: {
    id: 'formwright.fileUpload.chooseFiles',
    message: 'Choose files',
    description: "The drop zone's call to action, for several files",
  },
  dropToAdd: {
    id: 'formwright.fileUpload.dropToAdd',
    message: 'Drop to add',
    description: 'Shown while files are dragged over the drop zone',
  },
  orDropHere: {
    id: 'formwright.fileUpload.orDropHere',
    message: 'or drop here',
    description: 'Follows "Choose a file" when files can be dropped',
  },
  notAccepted: {
    id: 'formwright.fileUpload.notAccepted',
    message: 'Not an accepted type: {names}',
    description: 'Dropped files that were turned away; {names} is a comma-separated list',
  },
  remove: {
    id: 'formwright.fileUpload.remove',
    message: 'Remove {name}',
    description: "Accessible name of a file's remove button; {name} is the file name",
  },
  retry: {
    id: 'formwright.fileUpload.retry',
    message: 'Retry',
    description: 'Button that retries a failed upload',
  },
  uploading: {
    id: 'formwright.fileUpload.uploading',
    message: 'Uploading {name}',
    description: "Accessible name of an upload's progress bar; {name} is the file name",
  },
  uploadFailed: {
    id: 'formwright.fileUpload.uploadFailed',
    message: 'Upload failed',
    description: 'Shown when an upload fails without an error message',
  },
} satisfies Record<string, Message>
