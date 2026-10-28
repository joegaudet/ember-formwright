# @ember-formwright/file-upload

File inputs and drop zones for Formwright, powered by
[ember-file-upload](https://ember-file-upload.pages.dev) 10.

```bash
npm install @ember-formwright/ember @ember-formwright/file-upload ember-file-upload
```

```ts
// app/app.ts
import { registerFileUploadControls } from '@ember-formwright/file-upload'
import '@ember-formwright/file-upload/theme.css' // optional; after the Formwright theme

registerFileUploadControls() // @control="file" and @control="files"
```

```gts
{{! stores a File }}
<f.Field @for="resume" @control="file" @label="Résumé" as |field|>
  <field.Control @accept=".pdf" />
</f.Field>

{{! uploads straight away, and stores what @upload resolves to }}
<f.Field @for="attachments" @control="files" @label="Attachments" @optionLabel="name" as |field|>
  <field.Control @upload={{this.upload}} />
</f.Field>
```

```ts
upload: UploadFn = async file => {
  const response = await file.upload('/api/attachments') // file is ember-file-upload's UploadFile
  return response.json()
}
```

`file` stores one value (or `null`), `files` an array. Without `@upload` the value is the
native `File`; with it, whatever the promise resolves to. Each control renders a drop zone
around a native `<input type="file">` and lists the stored files with their size and a remove
button. The list is drawn from the field's value, so reset and rollback just work; a stored
value is named by `@optionLabel` (else its `label` or `name`). `field.Control` also takes
`@accept` (applied to the picker and to drops) and `@prompt` (the zone's call to action).

## Testing

```ts
import { FileUploadHarness } from '@ember-formwright/file-upload/test-support'

class ApplicationForm extends FormHarness {
  @field(FileUploadHarness) declare resume: FileUploadHarness
}

await form.resume.select(new File(['%PDF'], 'cv.pdf', { type: 'application/pdf' }))
await form.resume.drop(photo)
await form.resume.waitForUploads() // select and drop don't wait for @upload
assert.deepEqual(form.resume.files, ['cv.pdf'])
await form.resume.remove('cv.pdf')
```

It also has `retry(name)`, `uploading`, `failed`, `rejected`, `input` and `dropzone`.

## Behaviour and known limits

- **Labels and focus.** The input carries the field's id, so `<label for>` names it and inline
  editing focuses it. It is visually hidden; the zone shows its focus ring, and is itself a
  label for the input, so a click on it opens the picker. The input also gets `@label` as
  `aria-label`, so the zone's text doesn't join its name.
- **`@accept`.** Applied by the picker, and by the drop zone, which names what it turned away.
- **Uploads.** A file is in the value once its upload succeeds. A failed upload stores nothing
  and shows the error's message with Retry and remove buttons. The form doesn't wait for
  uploads on submit; the control has `data-uploading` and `aria-busy="true"` while any runs.
  Uploads aren't cancelled when the field is torn down; their results are dropped.
- **Disabled and readonly.** Both disable the input, ignore drops and hide the remove buttons.
- **Queues.** Each control uses its own ember-file-upload queue, destroyed with the control.
- **Drops.** Only files dragged from the desktop are taken, as ember-file-upload does by default.
- **Native submit.** The input is cleared after each choice (so the same file can be picked
  again), so it doesn't submit with a native `<form>`. The wrapper carries `data-fw-name`.
- **Versions.** Ember 6.12+ and ember-file-upload 10.
