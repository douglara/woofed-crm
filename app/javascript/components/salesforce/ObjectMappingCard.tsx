import { useState } from 'react'
import { router } from '@inertiajs/react'
import { ChevronDown, ChevronUp, Plus, Trash2 } from 'lucide-react'

import type {
  FieldMapping,
  ObjectMapping,
  SalesforceField,
  SyncableObject,
  WoofedField
} from '@/types/salesforce'

interface ObjectMappingCardProps {
  syncableObject: SyncableObject
  mapping: ObjectMapping | undefined
  woofedModels: string[]
  woofedFields: Record<string, WoofedField[]>
  describeUrl: (salesforceObject: string) => string
  submitUrl: string
}

const INPUT_CLASSES =
  'rounded-md border color-border-default color-bg-surface-hard px-4 py-2 typography-body-900 color-fg-default focus:outline-none focus:color-border-harder'

/**
 * One card per Salesforce object. Nothing syncs until a mapping is saved and
 * enabled, so an accidental connection never floods the CRM.
 *
 * The Salesforce field list is fetched only when the card is opened: the
 * describe payload is hundreds of KB per object, and every org has different
 * custom fields, so it cannot be shipped with the page.
 */
const ObjectMappingCard = ({
  syncableObject,
  mapping,
  woofedModels,
  woofedFields,
  describeUrl,
  submitUrl
}: ObjectMappingCardProps) => {
  const [open, setOpen] = useState(false)
  const [enabled, setEnabled] = useState(mapping?.enabled ?? false)
  const [woofedModel, setWoofedModel] = useState(
    mapping?.woofed_model ?? syncableObject.woofed_model
  )
  const [fieldMappings, setFieldMappings] = useState<FieldMapping[]>(
    mapping?.field_mappings ?? []
  )
  const [salesforceFields, setSalesforceFields] = useState<SalesforceField[]>([])
  const [loadingFields, setLoadingFields] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)

  const loadSalesforceFields = async () => {
    setLoadingFields(true)
    setLoadError(null)

    try {
      const response = await fetch(describeUrl(syncableObject.salesforce_object), {
        headers: { Accept: 'application/json' }
      })
      const body = await response.json()

      if (!response.ok) {
        setLoadError(body.error ?? 'Could not read the object from Salesforce.')
        return
      }

      setSalesforceFields(body.fields)
    } catch {
      setLoadError('Could not read the object from Salesforce.')
    } finally {
      setLoadingFields(false)
    }
  }

  const toggleOpen = () => {
    const opening = !open
    setOpen(opening)

    if (opening && salesforceFields.length === 0 && !loadingFields) {
      void loadSalesforceFields()
    }
  }

  const updateFieldMapping = (index: number, changes: Partial<FieldMapping>) =>
    setFieldMappings(
      fieldMappings.map((fieldMapping, position) =>
        position === index ? { ...fieldMapping, ...changes } : fieldMapping
      )
    )

  const addFieldMapping = () =>
    setFieldMappings([
      ...fieldMappings,
      { salesforce_field: '', woofed_field: '', kind: 'attribute' }
    ])

  const removeFieldMapping = (index: number) =>
    setFieldMappings(fieldMappings.filter((_, position) => position !== index))

  const save = () =>
    router.post(submitUrl, {
      object_mapping: {
        salesforce_object: syncableObject.salesforce_object,
        woofed_model: woofedModel,
        enabled,
        field_mappings: fieldMappings.filter(
          (fieldMapping) => fieldMapping.salesforce_field && fieldMapping.woofed_field
        )
      }
    })

  const availableWoofedFields = woofedFields[woofedModel] ?? []

  return (
    <section className="rounded-md border color-border-default color-bg-surface-default">
      <header className="flex flex-wrap items-center justify-between gap-4 px-6 py-5">
        <div className="flex flex-wrap items-center gap-3">
          <input
            type="checkbox"
            className="checkbox"
            checked={enabled}
            onChange={(event) => setEnabled(event.target.checked)}
            aria-label={`Sync ${syncableObject.salesforce_object}`}
          />
          <span className="typography-sub-title-900 color-fg-hard">
            {syncableObject.salesforce_object}
          </span>
          <span className="typography-body-900 color-fg-extra-soft">→</span>
          <select
            className={INPUT_CLASSES}
            value={woofedModel}
            onChange={(event) => setWoofedModel(event.target.value)}
          >
            {woofedModels.map((model) => (
              <option key={model} value={model}>
                {model}
              </option>
            ))}
          </select>
        </div>

        <button
          type="button"
          onClick={toggleOpen}
          className="button-default-outline-secondary-sm"
        >
          {open ? <ChevronUp /> : <ChevronDown />}
          Fields
        </button>
      </header>

      {open && (
        <div className="flex flex-col gap-4 border-t color-border-default px-6 py-5">
          {loadingFields && (
            <p className="typography-body-900 color-fg-soft">
              Reading the object from Salesforce…
            </p>
          )}
          {loadError && (
            <p className="rounded-md border color-border-feedback-danger-default color-bg-feedback-danger-default px-4 py-2 typography-body-900 color-fg-feedback-danger">
              {loadError}
            </p>
          )}

          {fieldMappings.length === 0 && !loadingFields && (
            <p className="typography-body-900 color-fg-extra-soft">
              No field is mapped yet. Nothing of this object will be imported.
            </p>
          )}

          {fieldMappings.map((fieldMapping, index) => (
            <div key={index} className="flex flex-wrap items-center gap-3">
              <select
                className={`${INPUT_CLASSES} flex-1`}
                value={fieldMapping.salesforce_field}
                onChange={(event) =>
                  updateFieldMapping(index, { salesforce_field: event.target.value })
                }
              >
                <option value="">Salesforce field…</option>
                {salesforceFields.map((field) => (
                  <option key={field.name} value={field.name}>
                    {field.label} ({field.name})
                  </option>
                ))}
              </select>

              <span className="typography-body-900 color-fg-extra-soft">→</span>

              <select
                className={`${INPUT_CLASSES} flex-1`}
                value={fieldMapping.woofed_field}
                onChange={(event) => {
                  const selected = availableWoofedFields.find(
                    (field) => field.name === event.target.value
                  )
                  updateFieldMapping(index, {
                    woofed_field: event.target.value,
                    kind: selected?.kind ?? 'attribute'
                  })
                }}
              >
                <option value="">Woofed field…</option>
                {availableWoofedFields.map((field) => (
                  <option key={field.name} value={field.name}>
                    {field.label}
                  </option>
                ))}
              </select>

              <button
                type="button"
                onClick={() => removeFieldMapping(index)}
                aria-label="Remove field"
                className="button-default-blank-secondary-icon-only-sm"
              >
                <Trash2 />
              </button>
            </div>
          ))}

          <div className="flex flex-wrap items-center justify-between gap-3">
            <button
              type="button"
              onClick={addFieldMapping}
              className="button-default-outline-secondary-sm"
            >
              <Plus />
              Add field
            </button>

            <button
              type="button"
              onClick={save}
              className="button-default-fill-primary-sm"
            >
              Save mapping
            </button>
          </div>
        </div>
      )}
    </section>
  )
}

export default ObjectMappingCard
