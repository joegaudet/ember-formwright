import { tracked } from '@glimmer/tracking'

/** Edited inline: click a value, change it in a popover, confirm. */
export class Profile {
  @tracked displayName = 'Ada Lovelace'
  @tracked role = 'Analyst'
  @tracked timezone = 'Europe/London'
}
