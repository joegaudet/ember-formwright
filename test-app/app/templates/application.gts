import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form } from '@formwright/ember'
import { enumOptions } from '@formwright/real-enums'
import {
  Account,
  accountSchema,
  addressSchema,
  COUNTRIES,
  BILLING,
  CHANNELS,
} from '../demo/account.ts'
import { Profile } from '../demo/profile.ts'
import { Plan } from '../demo/plan.ts'

const wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

class Demo extends Component {
  account = new Account()
  profile = new Profile()
  @tracked saved = 0

  save = async () => {
    await wait(700)
    this.saved++
  }

  get snapshot() {
    const a = this.account
    return JSON.stringify(
      {
        name: a.name,
        email: a.email,
        plan: a.plan?.value ?? null,
        seats: a.seats,
        budget: a.budget,
        billing: a.billing,
        notify: a.notify,
        terms: a.terms,
        address: { city: a.address.city, country: a.address.country },
      },
      null,
      2,
    )
  }

  <template>
    <main class="demo">
      <section class="demo-card">
        <header>
          <h1>Create your workspace</h1>
          <p>Try submitting it empty. Errors come from a zod schema, are announced to screen
            readers, and focus moves to the first one.</p>
        </header>

        <Form
          @model={{this.account}}
          @name="account"
          @validator={{accountSchema}}
          @onSubmit={{this.save}}
          as |f|
        >
          <div class="row">
            <f.Field @for="name" @label="Your name" @required={{true}} />
            <f.Field @for="email" @control="email" @label="Work email" @required={{true}} />
          </div>
          <f.Field
            @for="plan"
            @control="select"
            @label="Plan"
            @options={{enumOptions Plan}}
            @hint="Options come straight from an enum class."
          />
          <div class="row">
            <f.Field @for="seats" @control="number" @label="Seats" @min={{1}} />
            <f.Field @for="budget" @control="currency" @label="Monthly budget" as |field|>
              <field.Control @currency="EUR" @locale="en-IE" />
            </f.Field>
          </div>
          <f.Field
            @for="billing"
            @control="radio"
            @label="Billing"
            @options={{BILLING}}
            @storeKey={{true}}
          />
          <f.Field
            @for="notify"
            @control="checkbox-group"
            @label="Notify me by"
            @options={{CHANNELS}}
            @storeKey={{true}}
            @max={{2}}
            @hint="Pick up to two."
          />
          <f.Form
            @model={{this.account.address}}
            @name="address"
            @legend="Office"
            @validator={{addressSchema}}
            as |a|
          >
            <div class="row">
              <a.Field @for="city" @label="City" />
              <a.Field
                @for="country"
                @control="select"
                @label="Country"
                @options={{COUNTRIES}}
                @storeKey={{true}}
              />
            </div>
          </f.Form>
          <f.Field @for="terms" @control="checkbox" @label="I accept the terms" />

          <div class="actions">
            <f.Submit>Create workspace</f.Submit>
            <f.Reset>Start over</f.Reset>
            <span class="status" aria-live="polite">
              {{#if f.state.isSubmitting}}Saving…{{else if f.state.isDirty}}Unsaved changes{{else if
                this.saved
              }}Saved ✓{{/if}}
            </span>
          </div>
        </Form>
      </section>

      <aside class="demo-side">
        <section class="demo-card">
          <h2>Inline editing</h2>
          <p>Click a value. The editor opens in a native popover; ✔ applies, Esc cancels.</p>
          <Form @model={{this.profile}} @name="profile" @inline={{true}} @callout={{true}} as |f|>
            <f.Field @for="displayName" @label="Display name" />
            <f.Field @for="role" @label="Role" />
            <f.Field @for="timezone" @label="Time zone" />
          </Form>
        </section>
        <section class="demo-card">
          <h2>The model, live</h2>
          <pre class="model">{{this.snapshot}}</pre>
        </section>
      </aside>
    </main>
  </template>
}

<template><Demo /></template>
