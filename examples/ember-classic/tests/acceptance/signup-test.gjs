import { module, test } from 'qunit'
import { visit } from '@ember/test-helpers'
import { setupApplicationTest } from 'ember-qunit'
import { form } from '@formwright/test-support'

module('Acceptance | signup', function (hooks) {
  setupApplicationTest(hooks)

  test('the v2 addon works in a classic ember-cli build', async function (assert) {
    await visit('/')
    console.log('HTML', document.querySelector('#ember-testing').innerHTML)
    const signup = form('signup')

    await signup.field('name').fillIn('Ada')
    await signup.submit()
    assert.deepEqual(signup.field('email').errors, ['Email is required'])

    await signup.field('email').fillIn('ada@example.com')
    assert.deepEqual(signup.field('email').errors, [])
  })
})
