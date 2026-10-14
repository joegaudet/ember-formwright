import { tracked } from '@glimmer/tracking'
import { z } from 'zod'
import { Plan } from './plan.ts'

export class Address {
  @tracked city = 'Lisbon'
  @tracked country = 'pt'
}

export class Account {
  @tracked name = ''
  @tracked email = ''
  @tracked plan: Plan | null = Plan.Team
  @tracked seats: number | null = 3
  @tracked budget: number | null = 1200
  @tracked billing = 'monthly'
  @tracked notify: string[] = ['email']
  @tracked terms = false
  address = new Address()
}

export const accountSchema = z.object({
  name: z.string().min(2, 'Tell us your name'),
  email: z.string().email('That email looks off'),
  seats: z.number({ message: 'How many seats?' }).int().min(1, 'At least one seat'),
  terms: z.literal(true, { message: 'Please accept the terms' }),
})

export const addressSchema = z.object({
  city: z.string().min(1, 'City is required'),
})

export const COUNTRIES = [
  { id: 'pt', label: 'Portugal' },
  { id: 'ca', label: 'Canada' },
  { id: 'jp', label: 'Japan' },
]

export const BILLING = [
  { id: 'monthly', label: 'Monthly' },
  { id: 'yearly', label: 'Yearly (2 months free)' },
]

export const CHANNELS = [
  { id: 'email', label: 'Email' },
  { id: 'sms', label: 'SMS' },
  { id: 'push', label: 'Push' },
]
