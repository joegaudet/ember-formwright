/**
 * Type-only fixture: `pnpm typecheck` checks that `@for` is typed against the form's model.
 * Each `@glint-expect-error` asserts that the path below it is rejected. Nothing here renders.
 */
import type { TOC } from '@ember/component/template-only'
import { Form } from '@ember-formwright/ember'
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
