/** A real-enums-style enum: a String subclass with `values`, `value` and `label`. */
export class Plan extends String {
  readonly value: string
  readonly label: string
  constructor(value: string, label: string) {
    super(value)
    this.value = value
    this.label = label
  }
  get id() {
    return this
  }
  static Hobby = new Plan('hobby', 'Hobby — free')
  static Team = new Plan('team', 'Team — $12/seat')
  static Enterprise = new Plan('enterprise', 'Enterprise — talk to us')
  static get values(): Plan[] {
    return Object.values(this).filter((m): m is Plan => m instanceof Plan)
  }
}
