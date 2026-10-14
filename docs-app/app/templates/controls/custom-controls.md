# Custom controls

A control is any component that renders `@value` and calls `@onChange(newValue)`. Formwright
gives it the rest: an id for the label, disabled/readonly/required, `aria-invalid`, the
options, and its place in the form's dirty state, validation and reset.

## The contract

```ts
import type { ControlSignature } from '@ember-formwright/ember'

// Args a control receives (all from its field):
//   id          put it on the focusable element; the label points at it
//   name, type  the field's full path, and the control name it was given
//   value       the current value
//   onChange    call it with the new value
//   disabled, readonly, required, invalid, describedBy, placeholder
//   options, optionKey, optionLabel, storeKey, min, max, step, …
class MyControl extends Component<ControlSignature<number>> {}
```

## Use it: pass it, or register it

Pass the component to `@control`, or register it once under a name and use the name
everywhere. Register it with `{ group: true }` when it renders several inputs (like radios):
its field then renders a `<fieldset>` whose `<legend>` is the label.

<Example @name="custom-rating" @title="A star rating" />

```ts
import { registerControl } from '@ember-formwright/ember'

registerControl('rating', StarRating, { group: true }) // then @control="rating"
```

The **Test** tab shows the other half: a `RatingHarness` that subclasses `FieldHarness`, so
tests can call `feedback.quality.rate(5)`.

## One field, a whole object

A control can edit an object. This one binds `{ min, max }` at a single path, which is how
ember-foxy-forms' composite fields (an array `@for` with `@withMapping`) translate.

<Example @name="custom-price-range" @title="A price range" />

## More ideas

The original ember-foxy-forms docs walked through an image picker, a map, a rich-text editor
and a JSON editor. Each is the same recipe:

1. Wrap the widget in a component with `ControlSignature<YourValue>`.
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
