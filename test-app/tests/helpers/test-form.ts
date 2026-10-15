import {
  FormHarness,
  InputHarness,
  NumberHarness,
  CurrencyHarness,
  SelectHarness,
  RadioHarness,
  CheckboxHarness,
  CheckboxGroupHarness,
  field,
  form,
} from '@ember-formwright/test-support'

export class AddressForm extends FormHarness {
  @field(InputHarness) declare city: InputHarness
}

/** One harness for the fields the integration tests render, created once per test. */
export class TestForm extends FormHarness {
  @field(InputHarness) declare name: InputHarness
  @field(InputHarness) declare email: InputHarness
  @field(InputHarness) declare bio: InputHarness
  @field(InputHarness, 'address.city') declare city: InputHarness
  @field(NumberHarness) declare qty: NumberHarness
  @field(CurrencyHarness) declare price: CurrencyHarness
  @field(SelectHarness) declare size: SelectHarness
  @field(RadioHarness, 'size') declare sizeRadio: RadioHarness
  @field(SelectHarness) declare color: SelectHarness
  @field(SelectHarness) declare state: SelectHarness
  @field(RadioHarness) declare raw: RadioHarness
  @field(CheckboxHarness) declare agree: CheckboxHarness
  @field(CheckboxGroupHarness) declare sizes: CheckboxGroupHarness
  @form(AddressForm) declare address: AddressForm
}
