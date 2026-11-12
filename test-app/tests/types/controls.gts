/**
 * Type-only fixture: `pnpm typecheck` checks that a field's control fits the value at its
 * `@for` path, and that a field only takes the args its control declares. Each
 * `@glint-expect-error` asserts that the line below it is rejected. Nothing here renders.
 */
import type { TOC } from '@ember/component/template-only'
import {
  Form,
  registerControl,
  type ControlName,
  type ControlSignature,
  type ItemOf,
  type MaxArgs,
  type OptionAccessor,
  type OptionArgs,
} from '@ember-formwright/ember'
// Its declarations type @control="date-picker".
import '@ember-formwright/power-calendar'

declare module '@ember-formwright/ember' {
  interface FormwrightControls {
    /** A control added by name, as an add-on registers one. */
    stars: ControlSignature<number | null, { max?: number }>
  }
  interface FormwrightChoiceControls<T> {
    /** A built-in replaced with more args, as Joinery replaces its controls. */
    'checkbox-group': ControlSignature<
      ItemOf<T>[],
      OptionArgs<ItemOf<T>> & MaxArgs & { optionDescription?: OptionAccessor }
    >
  }
}

enum Plan {
  Solo = 'solo',
  Team = 'team',
}

interface Tag {
  id: string
  label: string
  blurb: string
}

interface Address {
  city: string
}

interface Profile {
  departure: string
  meta: any
  labels: readonly string[]
  volume: number
  name: string
  nickname: string | null
  age: number
  seats: number | null
  terms: boolean
  plan: Plan | null
  country: string | null
  tags: Tag[]
}

const plans = [Plan.Solo, Plan.Team]
const words = ['solo', 'team']
const countries = [{ id: 'pt', label: 'Portugal' }]
const upper = (text: string) => text.toUpperCase()
const tags: Tag[] = [{ id: 'a', label: 'A', blurb: 'The first' }]

/** A custom control passed as a component: it edits strings. */
const Shout = <template></template> as TOC<ControlSignature<string>>

/** Each control fits the value at its path. */
export const Fits: TOC<{ Args: { profile: Profile; useKey: boolean } }> = <template>
  <Form @model={{@profile}} as |f|>
    <f.Field @for="name" />
    <f.Field @for="name" @control="email" @maxLength={{40}} @showCount={{true}} />
    <f.Field @for="nickname" @control="text" />
    <f.Field @for="name" @control="textarea" />
    <f.Field @for="seats" @control="number" @min={{1}} @step={{1}} />
    <f.Field @for="seats" @control="currency" @currency="EUR" @locale="pt-PT" />
    <f.Field @for="terms" @control="checkbox" />
    <f.Field @for="plan" @control="select" @options={{plans}} />
    <f.Field @for="plan" @control="radio" @options={{plans}} />
    <f.Field
      @for="country"
      @control="select"
      @options={{countries}}
      @optionKey="id"
      @storeKey={{true}}
    />
    <f.Field @for="tags" @control="checkbox-group" @options={{tags}} @max={{2}} />
    {{! a control's own args, not ones a field passes on, go through the yielded control }}
    <f.Field @for="tags" @control="checkbox-group" @options={{tags}} as |field|>
      <field.Control @optionDescription="blurb" />
    </f.Field>
    <f.Field @for="seats" @control="stars" @max={{5}} />
    {{! a date picker never clears: a plain string path holds it }}
    <f.Field @for="departure" @control="date-picker" />
    {{! below an any, values stay any }}
    <f.Field @for="meta.title" @control="text" @format={{upper}} />
    {{! a readonly list can be shown and replaced }}
    <f.Field @for="labels" @control="checkbox-group" @options={{words}} />
    {{! @storeKey known only at runtime }}
    <f.Field @for="plan" @control="select" @options={{plans}} @storeKey={{@useKey}} />
    {{! a range can't be emptied: it fits a plain number }}
    <f.Field @for="volume" @control="range" @min={{0}} @max={{11}} />
    <f.Field @for="name" @control={{Shout}} />
    <f.Field @for="name" as |field|><field.Control @maxLength={{3}} /></f.Field>
  </Form>
</template>

/** A control that doesn't fit its path, or an arg its control doesn't take, is rejected. */
export const Misfits: TOC<{ Args: { profile: Profile } }> = <template>
  <Form @model={{@profile}} as |f|>
    {{! @glint-expect-error: a checkbox stores a boolean, name is a string }}
    <f.Field @for="name" @control="checkbox" />
    {{! @glint-expect-error: a text input stores a string, seats is a number }}
    <f.Field @for="seats" @control="text" />
    {{! @glint-expect-error: without @control a field is a text input }}
    <f.Field @for="seats" />
    {{! @glint-expect-error: emptying a number input stores null; age can't hold it }}
    <f.Field @for="age" @control="number" />
    {{! @glint-expect-error: no such control }}
    <f.Field @for="name" @control="nope" />
    {{! @glint-expect-error: only currency takes @currency }}
    <f.Field @for="name" @currency="EUR" />
    {{! @glint-expect-error: an email has no bounds }}
    <f.Field @for="name" @control="email" @min={{3}} />
    {{! @glint-expect-error: a checkbox has no length }}
    <f.Field @for="terms" @control="checkbox" @maxLength={{3}} />
    {{! @glint-expect-error: the options aren't plans }}
    <f.Field @for="plan" @control="select" @options={{words}} />
    {{! @glint-expect-error: a checkbox group stores a list; name isn't one }}
    <f.Field @for="name" @control="checkbox-group" @options={{words}} />
    {{! @glint-expect-error: a field passes on only the args it knows }}
    <f.Field @for="tags" @control="checkbox-group" @optionDescription="blurb" />
    <f.Field @for="plan" @control="select" @options={{plans}} as |field|>
      {{! @glint-expect-error: only the replaced checkbox-group takes @optionDescription }}
      <field.Control @optionDescription="blurb" />
    </f.Field>
    {{! @glint-expect-error: a select stores null for its blank option; country can't hold it }}
    <f.Field @for="name" @control="select" @options={{words}} />
    {{! @glint-expect-error: @storeKey is for choice controls }}
    <f.Field @for="terms" @control="checkbox" @storeKey={{true}} />
    {{! @glint-expect-error: Shout edits strings; seats is a number }}
    <f.Field @for="seats" @control={{Shout}} />
    <f.Field @for="name" as |field|>
      {{! @glint-expect-error: the yielded control is a text input }}
      <field.Control @currency="EUR" />
    </f.Field>
  </Form>
</template>

const shout = (city: string) => city.toUpperCase()

/** A dictionary keeps its values' types. */
export const Dictionary: TOC<{ Args: { byCountry: Record<string, Address> } }> = <template>
  <Form @model={{@byCountry}} as |f|>
    <f.Field @for="pt.city" @format={{shout}} />
    {{! @glint-expect-error: a city is a string }}
    <f.Field @for="pt.city" @control="checkbox" />
  </Form>
</template>

/** A union model keeps its paths' types. */
export const Union: TOC<{ Args: { either: { a: string } | { b: number } } }> = <template>
  <Form @model={{@either}} as |f|>
    {{! @glint-expect-error: a is a string }}
    <f.Field @for="a" @control="checkbox" />
  </Form>
</template>

/** registerControl checks a declared choice name's component, too. Never called: types only. */
export function registerChecks() {
  // @ts-expect-error: a select must show what its path holds, not only strings
  registerControl('select', Shout)
}

/** A loosely typed model, or a changeset's unknown part, takes any control. */
export const Loose: TOC<{
  Args: { record: Record<string, unknown>; name: ControlName }
}> = <template>
  <Form @model={{@record}} as |f|>
    <f.Field @for="anything" @control="checkbox" />
    <f.Field @for="anything" @control="number" />
    <f.Field @for="anything" @control="select" @options={{words}} />
    <f.Field @for="anything" />
    {{! a control chosen at runtime }}
    <f.Field @for="anything" @control={{@name}} />
  </Form>
</template>
