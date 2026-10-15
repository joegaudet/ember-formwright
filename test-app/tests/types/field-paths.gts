/**
 * Type-only fixture: `pnpm typecheck` checks that the form's interface is typed against its
 * model: `@for` paths, field values, `@format`, errors, validators and `@onChange`. Each
 * `@glint-expect-error` / `@ts-expect-error` asserts that the line below it is rejected.
 * Nothing here renders.
 */
import type { TOC } from '@ember/component/template-only'
import {
  Form,
  type ErrorMap,
  type Path,
  type PathValue,
  type ValidatorFn,
} from '@ember-formwright/ember'
import type { Account } from 'test-app/demo/account'

interface Line {
  name: string
  qty: number
}

interface Order {
  ref: string
  customer: { name: string; address: { city: string } }
  lines: Line[]
  placedAt: Date
  save(): Promise<void>
}

export const Paths: TOC<{ Args: { account: Account; order: Order } }> = <template>
  <Form @model={{@account}} as |f|>
    <f.Field @for="name" />
    <f.Field @for="address.city" />
    {{! @glint-expect-error: typo }}
    <f.Field @for="nmae" />
    {{! @glint-expect-error: no such nested key }}
    <f.Field @for="address.nope" />
  </Form>

  <Form @model={{@order}} as |f|>
    <f.Field @for="customer.address.city" />
    <f.Field @for="lines.0.name" />
    <f.Field @for="lines[0].name" />
    <f.Field @for="lines" />
    <f.Field @for="placedAt" />
    {{! @glint-expect-error: no such key on a line }}
    <f.Field @for="lines.0.price" />
    {{! @glint-expect-error: indexes are numbers }}
    <f.Field @for="lines.first.name" />
    {{! @glint-expect-error: methods aren't paths }}
    <f.Field @for="save" />
    {{! @glint-expect-error: Dates aren't recursed into }}
    <f.Field @for="placedAt.getTime" />
  </Form>
</template>

/** A nested form keeps its own model's type. */
export const NestedPaths: TOC<{ Args: { account: Account } }> = <template>
  <Form @model={{@account}} as |f|>
    <f.Form @model={{@account.address}} as |a|>
      <a.Field @for="city" />
      {{! @glint-expect-error: name is on Account, not Address }}
      <a.Field @for="name" />
    </f.Form>
  </Form>
</template>

/** Loose models keep accepting any path. */
export const LoosePaths: TOC<{
  Args: { any: any; object: object; record: Record<string, unknown> }
}> = <template>
  <Form @model={{@any}} as |f|><f.Field @for="any.thing" /></Form>
  <Form @model={{@object}} as |f|><f.Field @for="any.thing" /></Form>
  <Form @model={{@record}} as |f|><f.Field @for="any.thing" /></Form>
</template>

// ---- values follow the path -------------------------------------------------------------

const text = (value: string) => value
const count = (value: number | null) => String(value)
const formatCity = (city: string) => city.toUpperCase()

/** A field's value, its @format and its block's `value` are typed by `@for`. */
export const Values: TOC<{ Args: { account: Account; order: Order } }> = <template>
  <Form @model={{@account}} as |f|>
    <f.Field @for="name" as |field|>{{text field.value}}</f.Field>
    <f.Field @for="seats" as |field|>{{count field.value}}</f.Field>
    {{! @glint-expect-error: seats is a number, not a string }}
    <f.Field @for="seats" as |field|>{{text field.value}}</f.Field>
    <f.Field @for="address.city" @format={{formatCity}} />
    {{! @glint-expect-error: @format gets the seat count, not a string }}
    <f.Field @for="seats" @format={{formatCity}} />
    {{text f.state.model.name}}
  </Form>
  <Form @model={{@order}} as |f|>
    <f.Field @for="lines[0].name" as |field|>{{text field.value}}</f.Field>
    <f.Field @for="lines.0.qty" as |field|>{{count field.value}}</f.Field>
  </Form>
  <Form @model={{@account}} as |f|>
    <f.Form @model={{@account.address}} as |a|>
      <a.Field @for="city" as |field|>{{text field.value}}</a.Field>
    </f.Form>
  </Form>
</template>

// ---- types in TypeScript ----------------------------------------------------------------

export const city: PathValue<Account, 'address.city'> = 'Porto'
// @ts-expect-error: seats holds a number
export const seats: PathValue<Account, 'seats'> = 'three'
export const line: PathValue<Order, 'lines[0].qty'> = 2
export const path: Path<Account> = 'address.country'

/** Error keys are model paths (or '' for form-level errors). */
export const rules: ValidatorFn<Account> = account =>
  account.name ? {} : { name: ['Name it'], 'address.city': ['Where?'], '': ['Fix the form'] }
/** Key typos are caught where the return type says ErrorMap<Model>. */
// @ts-expect-error: no such path
export const typo = (): ErrorMap<Account> => ({ nmae: ['Name it'] })
export const loose: ErrorMap = { anything: ['goes'] }

/** @onChange's value is typed by its path; @didNotSubmit gets the model's ErrorMap. */
export const onChange = <P extends Path<Account>>(path: P, value: PathValue<Account, P>) =>
  String(value)
export const onInvalid = (errors: ErrorMap<Account>) => errors.name
// @ts-expect-error: not a path of Account
export const badKey = (errors: ErrorMap<Account>) => errors.nmae

export const Hooks: TOC<{ Args: { account: Account } }> = <template>
  <Form
    @model={{@account}}
    @validator={{rules}}
    @onChange={{onChange}}
    @didNotSubmit={{onInvalid}}
    as |f|
  >
    <f.Field @for="name" />
  </Form>
</template>
