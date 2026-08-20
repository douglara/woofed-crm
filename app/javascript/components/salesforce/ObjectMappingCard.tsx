import { useState } from 'react'
import { ChevronDown, ChevronUp, Plus, Trash2 } from 'lucide-react'

import { Spinner } from '@/components/ui/spinner'
import { Switch } from '@/components/ui/switch'
import { usePendingVisit } from '@/components/salesforce/use-pending-visit'
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

// `min-w-0` is what keeps the field pickers inside the card: a select is as wide
// as its widest option, org field names run long, and a grid or flex item refuses
// to shrink under its content until its automatic minimum is lifted. Letting them
// shrink beats forcing full width, which would drop the model picker out of the
// header row onto a line of its own.
const INPUT_CLASSES =
  'min-w-0 rounded-md border color-border-default color-bg-surface-hard px-4 py-2 typography-body-900 color-fg-default focus:outline-none focus:color-border-harder'

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
  const { isPending, visit } = usePendingVisit()
  const [open, setOpen] = useState(false)
  const [enabled, setEnabled] = useState(mapping?.enabled ?? false)
  const [woofedModel, setWoofedModel] = useState(
    mapping?.woofed_model ?? syncableObject.woofed_model ?? woofedModels[0]
  )
  const [fieldMappings, setFieldMappings] = useState<FieldMapping[]>(
    mapping?.field_mappings ?? []
  )
  const [salesforceFields, setSalesforceFields] = useState<SalesforceField[]>([])
  const [loadingFields, setLoadingFields] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)

  // Only Deal needs these: a Woofed deal requires a stage and a contact that no
  // Salesforce field carries. The other models go straight to save.
  const savedOptions = (mapping?.options ?? {}) as {
    stage_field?: string
    company_field?: string
    contact_field?: string
    create_placeholder_contact?: boolean
  }
  const [stageField, setStageField] = useState(savedOptions.stage_field ?? '')
  const [companyField, setCompanyField] = useState(savedOptions.company_field ?? '')
  const [contactField, setContactField] = useState(savedOptions.contact_field ?? '')
  const [placeholderContact, setPlaceholderContact] = useState(
    savedOptions.create_placeholder_contact === true
  )
  const isDeal = woofedModel === 'Deal'

  // The company can only come from a lookup, since a company is resolved through
  // the identity map and nothing else. The contact accepts any field: an id, an
  // email or a phone all identify a person, and the loader tries the three.
  const lookupFields = salesforceFields.filter((field) => field.type === 'reference')

  // A deal is saved with whatever the settings above resolve, so an empty field
  // list still imports it -- nameless, which no column forbids and no screen
  // makes readable. Worth saying out loud rather than letting it happen quietly.
  const mapsName = fieldMappings.some(
    (fieldMapping) =>
      fieldMapping.woofed_field === 'name' && fieldMapping.kind === 'attribute'
  )
  const missingDealName = isDeal && !mapsName && !loadingFields

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

  // `options` is left out entirely for the other models, so saving a Contact
  // mapping never writes deal settings onto it.
  const persist = (nextEnabled: boolean) =>
    visit(submitUrl, {
      data: {
        object_mapping: {
          salesforce_object: syncableObject.salesforce_object,
          woofed_model: woofedModel,
          enabled: nextEnabled,
          field_mappings: fieldMappings.filter(
            (fieldMapping) => fieldMapping.salesforce_field && fieldMapping.woofed_field
          ),
          ...(isDeal
            ? {
                options: {
                  stage_field: stageField,
                  company_field: companyField,
                  contact_field: contactField,
                  create_placeholder_contact: placeholderContact
                }
              }
            : {})
        }
      }
    })

  // The switch saves on its own, and it saves the whole card rather than the one
  // flag: turning an object on starts a sync, and that sync has to run with the
  // field mappings the user is looking at, not with whatever was stored before
  // they edited them.
  //
  // It moves before the answer arrives, because a switch that waits out a round
  // trip to move reads as broken rather than as busy.
  const toggleEnabled = (nextEnabled: boolean) => {
    setEnabled(nextEnabled)
    persist(nextEnabled)
  }

  const save = () => persist(enabled)

  const availableWoofedFields = woofedFields[woofedModel] ?? []

  return (
    <section className="rounded-md border color-border-default color-bg-surface-default">
      <header className="flex flex-wrap items-center justify-between gap-4 px-6 py-5">
        <div className="flex flex-wrap items-center gap-3">
          <Switch
            checked={enabled}
            disabled={isPending(submitUrl)}
            onCheckedChange={toggleEnabled}
            aria-label={`Sync ${syncableObject.salesforce_object}`}
          />

          <span className="typography-sub-title-900 color-fg-hard">
            {syncableObject.label}
          </span>
          {syncableObject.custom && (
            <span className="rounded-full color-bg-fill-hard px-2 py-0.5 typography-button-800 color-fg-highlight">
              custom
            </span>
          )}
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

          {/* Trailing the row, and holding its size whether or not it is
              spinning, so nothing in front of it moves while the card saves. */}
          <span className="flex size-4 items-center justify-center">
            {isPending(submitUrl) && <Spinner />}
          </span>
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

          {isDeal && (
            <div className="flex flex-col gap-4 rounded-md border color-border-default color-bg-surface-hard px-4 py-4">
              <div className="flex flex-col gap-1">
                <h3 className="typography-label-900 color-fg-hard">Deal settings</h3>
                <p className="typography-body-900 color-fg-soft">
                  A deal cannot exist without a stage. The value of the field
                  below is matched against your Woofed stage names, ignoring
                  upper and lower case — name them alike and there is nothing
                  else to configure.
                </p>
              </div>

              <div className="grid gap-2">
                <label
                  htmlFor={`stage-field-${syncableObject.salesforce_object}`}
                  className="typography-label-900 color-fg-soft"
                >
                  Field that holds the stage
                </label>
                <select
                  id={`stage-field-${syncableObject.salesforce_object}`}
                  className={INPUT_CLASSES}
                  value={stageField}
                  onChange={(event) => setStageField(event.target.value)}
                >
                  <option value="">StageName (standard opportunities)</option>
                  {salesforceFields.map((field) => (
                    <option key={field.name} value={field.name}>
                      {field.label} ({field.name})
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid gap-2">
                <label
                  htmlFor={`company-field-${syncableObject.salesforce_object}`}
                  className="typography-label-900 color-fg-soft"
                >
                  Lookup that points at the company
                </label>
                <select
                  id={`company-field-${syncableObject.salesforce_object}`}
                  className={INPUT_CLASSES}
                  value={companyField}
                  onChange={(event) => setCompanyField(event.target.value)}
                >
                  <option value="">AccountId (standard opportunities)</option>
                  {lookupFields.map((field) => (
                    <option key={field.name} value={field.name}>
                      {field.label} ({field.name})
                    </option>
                  ))}
                </select>
                <p className="typography-body-900 color-fg-extra-soft">
                  The object it points at has to be mapped and synced first —
                  the deal finds its company among the records already imported.
                </p>
              </div>

              <div className="grid gap-2">
                <label
                  htmlFor={`contact-field-${syncableObject.salesforce_object}`}
                  className="typography-label-900 color-fg-soft"
                >
                  Field that identifies the contact
                </label>
                <select
                  id={`contact-field-${syncableObject.salesforce_object}`}
                  className={INPUT_CLASSES}
                  value={contactField}
                  onChange={(event) => setContactField(event.target.value)}
                >
                  <option value="">None — use a contact of the company</option>
                  {salesforceFields.map((field) => (
                    <option key={field.name} value={field.name}>
                      {field.label} ({field.name})
                    </option>
                  ))}
                </select>
                <p className="typography-body-900 color-fg-extra-soft">
                  A lookup, an email or a phone all work — whichever the object
                  uses to say who the person is.
                </p>
              </div>

              <label className="flex items-start gap-3">
                <input
                  type="checkbox"
                  className="checkbox mt-1"
                  checked={placeholderContact}
                  onChange={(event) => setPlaceholderContact(event.target.checked)}
                />
                <span className="flex flex-col gap-1">
                  <span className="typography-label-900 color-fg-soft">
                    Create a contact named after the company when there is none
                  </span>
                  <span className="typography-body-900 color-fg-extra-soft">
                    Woofed requires a contact on every deal. Without this, a
                    record whose company has nobody on it is reported instead of
                    imported.
                  </span>
                </span>
              </label>
            </div>
          )}

          {fieldMappings.length === 0 && !loadingFields && !isDeal && (
            <p className="typography-body-900 color-fg-extra-soft">
              No field is mapped yet. Nothing of this object will be imported.
            </p>
          )}

          {missingDealName && (
            <p className="rounded-md border color-border-feedback-danger-default color-bg-feedback-danger-default px-4 py-2 typography-body-900 color-fg-feedback-danger">
              Nothing is mapped onto the deal name. The deals of this object will
              still be imported, with the stage, company and contact resolved
              above — but they will have no name. Map a Salesforce field onto{' '}
              <strong>Name</strong> below.
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

            {/* Saving a mapping twice enables the same object twice, and the
                second answer overwrites the first. */}
            <button
              type="button"
              disabled={isPending(submitUrl)}
              onClick={save}
              className="button-default-fill-primary-sm disabled:opacity-50"
            >
              {isPending(submitUrl) && <Spinner />}
              Save mapping
            </button>
          </div>
        </div>
      )}
    </section>
  )
}

export default ObjectMappingCard
