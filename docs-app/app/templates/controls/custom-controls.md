# Custom controls

A control is any component that renders `@value` and calls `@onChange(newValue)`. Formwright
gives it the rest: an id for the label, disabled/readonly/required, `aria-invalid`, the
options, and its place in the form's dirty state, validation and reset.

## The contract

```ts
import type { ControlSignature } from '@ember-formwright/ember'

// ControlSignature<Value, Extra, Element>. Every control receives the wiring:
//   id          put it on the focusable element; the label points at it
//   name, type  the field's full path, and the control name it was given
//   value       the value at the path: a Value, or null or undefined
//   onChange    call it with the new value
//   disabled, readonly, required, invalid, describedBy, placeholder, label, callout
// and the args of its own, `Extra`:
class Stepper extends Component<ControlSignature<number, { step?: number }>> {}
```

`Value` is what the control stores. A field only accepts a control whose `Value` its path can
hold: `Stepper` fits a `number` path, but not a `string` one. The field takes the control's own
args where it passes them on (`@options`, `@min`, `@max`, `@step`, `@maxLength`, `@currency`,
…). Any other arg goes through the yielded `Control`:

```gts
<f.Field @for="phone" @control="masked" as |field|>
  <field.Control @mask={{phoneMask}} />
</f.Field>
```

## Use it: pass it, or register it

Pass the component to `@control`, or register it once under a name and use the name
everywhere. Register it with `{ group: true }` when it renders several inputs (like radios):
its field then renders a `<fieldset>` whose `<legend>` is the label.

<Example @name="custom-rating" @title="A star rating" />

```ts
import { registerControl, type ControlSignature } from '@ember-formwright/ember'

registerControl('rating', StarRating, { group: true }) // then @control="rating"

// Declare the name too, so @control="rating" is typed: which paths it fits, which args it takes.
declare module '@ember-formwright/ember' {
  interface FormwrightControls {
    rating: ControlSignature<number>
  }
}
```

The **Test** tab shows the other half: a `RatingHarness` that subclasses `FieldHarness`, so
tests can call `feedback.quality.rate(5)`.

`registerControl` checks a declared name's component against its signature. A name declared
here replaces the built-in of that name.

A control that stores whatever its path holds, as a select stores its options, is declared in
`FormwrightChoiceControls<T>` instead, where `T` is the value at the field's path:

```ts
import type { ControlSignature, ItemOf, OptionArgs } from '@ember-formwright/ember'

declare module '@ember-formwright/ember' {
  interface FormwrightChoiceControls<T> {
    // One option; null when cleared.
    combobox: ControlSignature<NonNullable<T> | null, OptionArgs<NonNullable<T>>>
    // Several: the path is a list.
    tags: ControlSignature<ItemOf<T>[], OptionArgs<ItemOf<T>>>
  }
}
```

The add-on packages declare their default names (`phone`, `file`, `date-picker`, …). Register
one under another name and declare that name yourself.

## One field, a whole object

A control can edit an object. This one binds `{ min, max }` at a single path, which is how
ember-foxy-forms' composite fields (an array `@for` with `@withMapping`) translate.

<Example @name="custom-price-range" @title="A price range" />

## More ideas

The original ember-foxy-forms docs walked through an image picker, a map, a rich-text editor
and a JSON editor. Each is the same recipe:

1. Wrap the widget in a component with `ControlSignature<YourValue, YourArgs>`, and declare
   the name you register it under.
2. Put `@id` on its focusable element, or on the first one for a group.
3. Call `@onChange` whenever the widget's value changes. If the widget fires many events per
   edit, debounce here, or let `@requireConfirm` hold the value until the user applies it.
4. Give it a harness: a `FieldHarness` subclass with getters and actions that match how a
   user operates it.

<div class="callout">

**Coming from ember-foxy-forms**

Controls were found by name in `app/components/form-controls/` (`<name>`, `<name>-control` or
`ff-<name>`). Formwright doesn't resolve components by name: call `registerControl`, or pass
the component.

</div>
