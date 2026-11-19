# Accessibility testing

Run [axe](https://github.com/dequelabs/axe-core) at the end of every form test, after the form
has reached the state you want to check. Every example in this guide does, so its **Test** tab
shows the pattern.

```bash
npm install --save-dev ember-a11y-testing
```

```ts
import { a11yAudit } from 'ember-a11y-testing/test-support'

test('a failed signup', async function (assert) {
  await render(<template><Signup /></template>)
  const signup = new SignupForm()

  await signup.submit()
  assert.deepEqual(signup.email.errors, ['Enter your email'])
  await a11yAudit() // with the errors showing
})
```

Audit the states a user sees, not only the first render: with errors showing, with a callout
open, while a file uploads.

## Harnesses and ARIA

The [harnesses](../going-further/testing.md) find fields through `data-test-fw-*` selectors, not
through ARIA, so a passing harness test does not prove a field is accessible. Assert the ARIA you
rely on with `assert.dom`. `field.control` is the element a field's label points at:

```ts
await signup.submit()
assert.dom(signup.email.control).isFocused()
assert.dom(signup.email.control).hasAttribute('aria-invalid', 'true')
```

The [overview](overview.md) example's test checks focus, `aria-describedby` and the live
region this way.
