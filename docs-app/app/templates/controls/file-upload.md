# File upload

`@ember-formwright/file-upload` adds `file` and `files`: a drop zone around a native file
input, and the list of chosen files. It is built on
[ember-file-upload](https://ember-file-upload.pages.dev) 10.

```bash
npm install @ember-formwright/file-upload ember-file-upload
```

```ts
// app/app.ts
import { registerFileUploadControls } from '@ember-formwright/file-upload'
import '@ember-formwright/file-upload/theme.css' // optional: follows the Formwright theme

registerFileUploadControls() // @control="file" and @control="files"
```

## Choosing files

`file` stores one `File` (or `null`), and `files` an array of them. Choose with the button or
drop files on the zone; each chosen file is listed with its size and a remove button. The list
is drawn from the field's value, so reset and rollback put back what was there.

`@accept`, given to `field.Control`, is passed to the input as `accept`, and the drop zone
applies the same filter: `.pdf`, `image/*`, `text/csv`, ... A dropped file it turns away is
named under the zone.

<Example @name="controls-file-upload" @title="file and files" />

The field wires the input up like any other: its id (so `<label for>` names it and focus lands
on it), `name`, `required`, `aria-invalid` and `aria-describedby`. `@disabled` and `@readonly`
both disable it, and hide the remove buttons.

## Uploading as files are chosen

Give the control `@upload`: it receives each file as ember-file-upload's `UploadFile`, and
returns a promise of what the field stores, such as an id or a URL. Until it settles, the file
is listed with a progress bar (`file.progress`, which `file.upload(url)` keeps up to date). If
it fails, the file is marked failed with the error's message, stores nothing, and can be
retried or removed.

```ts
const upload: UploadFn = async file => {
  const response = await file.upload('/api/attachments')
  return response.json() // e.g. { id: 7, name: 'notes.pdf', url: '...' }
}
```

The list names a stored value with `@optionLabel` (or its `label` or `name`), as inline mode
does. Give the field a `@format` for anything else.

<Example @name="controls-file-upload-upload" @title="Upload on choose" />

<div class="callout">

**Submitting while files upload.** The form doesn't wait for uploads: a file is in the value
only once its upload has finished. While any upload runs, the control carries `data-uploading`
and `aria-busy="true"`. Validate that what you need is there, or disable your submit button
while it uploads.

</div>

## Testing

`FileUploadHarness`, from `@ember-formwright/file-upload/test-support`, adds `select(...files)`,
`drop(...files)`, `remove(name)`, `retry(name)`, `waitForUploads()`, and `files`, `uploading`,
`failed` and `rejected` to [`FieldHarness`](../going-further/testing.md#field-harnesses).
`select` and `drop` don't wait for `@upload`; call `waitForUploads()` for that.

```ts
await form.resume.select(new File(['%PDF'], 'cv.pdf', { type: 'application/pdf' }))
await form.attachments.drop(photo)
await form.attachments.waitForUploads()
assert.deepEqual(form.attachments.files, ['cv.pdf', 'photo.png'])
```

<div class="callout">

**Known limits**

- The file input is reset after each choice, so the same file can be chosen twice; it doesn't
  take part in a native `<form>` submit. The control sets `data-fw-name` with the field's path.
- Uploads are not cancelled when the field goes away; their results are dropped.
- Only files dragged from the desktop are taken, not images dragged from another page.

</div>
