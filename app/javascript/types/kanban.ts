export interface User {
  id: number
  full_name: string
  avatar_url: string | null
}

export interface Contact {
  id: number
  full_name: string
}

export interface Event {
  id: number
  primary_date: string
  overdue: boolean
}

export interface Deal {
  id: number
  name: string
  status: 'open' | 'won' | 'lost'
  position: number
  total_amount_in_cents: number
  contact: Contact
  users: User[]
  next_event_planned: Event | null
}

export interface Stage {
  id: number
  name: string
  position: number
  total_amount: number
  total_quantity: number
  total_quantity_resume: string
  deals: Deal[]
  has_more_deals: boolean
  next_page: number | null
}

export interface Pipeline {
  id: number
  name: string
  stages: Stage[]
}

export interface KanbanPageProps {
  pipeline: Pipeline
  pipelines: { id: number; name: string }[]
  filter_status_deal: string
  account_id: number
  account_currency: string
  user_locale: string
}
