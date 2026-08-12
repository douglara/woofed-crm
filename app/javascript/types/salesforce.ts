export interface SalesforceConnection {
  id: number
  name: string
  status: 'inactive' | 'active' | 'syncing' | 'error'
  environment: 'production' | 'sandbox'
  instance_url: string
  organization_id: string
  token_expires_at: string | null
  connected: boolean
}

export interface FieldMapping {
  // Indexable so the mapping can be posted straight through Inertia's router,
  // which only accepts FormDataConvertible values.
  [key: string]: string | undefined
  salesforce_field: string
  woofed_field: string
  kind: 'attribute' | 'custom_attribute'
  transform?: string
}

export interface ObjectMapping {
  id: number
  salesforce_object: string
  woofed_model: string
  enabled: boolean
  field_mappings: FieldMapping[]
  options: Record<string, unknown>
}

export interface SyncableObject {
  salesforce_object: string
  woofed_model: string
}

export interface WoofedField {
  name: string
  label: string
  kind: 'attribute' | 'custom_attribute'
}

export interface SalesforceField {
  name: string
  label: string
  type: string
  custom: boolean
}
