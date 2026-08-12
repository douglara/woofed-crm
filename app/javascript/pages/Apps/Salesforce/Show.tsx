import { useState } from 'react'
import { Head, usePage } from '@inertiajs/react'

import ConnectForm from '@/components/salesforce/ConnectForm'
import ConnectionSummary from '@/components/salesforce/ConnectionSummary'
import ObjectMappingCard from '@/components/salesforce/ObjectMappingCard'
import SyncPanel from '@/components/salesforce/SyncPanel'
import type {
  ObjectMapping,
  SalesforceConnection,
  SyncableObject,
  SyncRun,
  WoofedField
} from '@/types/salesforce'

interface SalesforceShowProps {
  connection: SalesforceConnection | null
  callback_url: string
  scopes: string
  syncable_objects: SyncableObject[]
  woofed_models: string[]
  woofed_fields: Record<string, WoofedField[]>
  object_mappings: ObjectMapping[]
  sync_runs: SyncRun[]
}

const SalesforceShow = ({
  connection,
  callback_url,
  scopes,
  syncable_objects,
  woofed_models,
  woofed_fields,
  object_mappings,
  sync_runs
}: SalesforceShowProps) => {
  const { current_account } = usePage().props
  const [addedObject, setAddedObject] = useState('')
  const basePath = `/accounts/${current_account.id}/apps/salesforce`

  const mappedObjects = object_mappings.map((mapping) => mapping.salesforce_object)
  const objectFor = (name: string) =>
    syncable_objects.find((object) => object.salesforce_object === name) ?? {
      salesforce_object: name,
      label: name,
      custom: false,
      woofed_model: null
    }

  // Already mapped objects first, then the one the user just picked. The org can
  // have hundreds of objects, so the rest stay behind the picker.
  const cards = [
    ...object_mappings.map((mapping) => ({
      syncableObject: objectFor(mapping.salesforce_object),
      mapping
    })),
    ...(addedObject && !mappedObjects.includes(addedObject)
      ? [{ syncableObject: objectFor(addedObject), mapping: undefined }]
      : [])
  ]

  const availableObjects = syncable_objects.filter(
    (object) =>
      !mappedObjects.includes(object.salesforce_object) &&
      object.salesforce_object !== addedObject
  )

  return (
    <div className="h-full overflow-y-auto color-bg-surface-hard">
      <Head title="Salesforce" />

      <section className="mx-auto flex max-w-4xl flex-col gap-8 p-8">
        <header className="flex flex-col gap-1">
          <h1 className="typography-title-700 color-fg-hard">Salesforce</h1>
          <p className="typography-body-1000 color-fg-soft">
            Read records from a Salesforce org into Woofed. Nothing is written
            back to Salesforce.
          </p>
        </header>

        {connection?.connected && (
          <ConnectionSummary connection={connection} disconnectUrl={basePath} />
        )}

        {/* Reconnecting edits the existing connection: an install talks to a
            single org, so there is no "add connection" affordance. */}
        <ConnectForm
          connection={connection}
          callbackUrl={callback_url}
          scopes={scopes}
          submitUrl={basePath}
        />

        {connection?.connected && (
          <div className="flex flex-col gap-4">
            <div className="flex flex-col gap-1">
              <h2 className="typography-sub-title-950 color-fg-hard">Mapping</h2>
              <p className="typography-body-900 color-fg-soft">
                Nothing syncs until an object is mapped and enabled. Custom
                objects can be mapped onto any Woofed model.
              </p>
            </div>

            {cards.map(({ syncableObject, mapping }) => (
              <ObjectMappingCard
                key={syncableObject.salesforce_object}
                syncableObject={syncableObject}
                mapping={mapping}
                woofedModels={woofed_models}
                woofedFields={woofed_fields}
                describeUrl={(salesforceObject) =>
                  `${basePath}/describe/${salesforceObject}`
                }
                submitUrl={`${basePath}/object_mappings`}
              />
            ))}

            <div className="grid gap-2 rounded-md border color-border-default color-bg-surface-default px-6 py-5">
              <label
                htmlFor="salesforce-add-object"
                className="typography-label-900 color-fg-soft"
              >
                Map another object
              </label>
              <select
                id="salesforce-add-object"
                className="rounded-md border color-border-default color-bg-surface-hard px-4 py-2 typography-body-900 color-fg-default focus:outline-none focus:color-border-harder"
                value=""
                onChange={(event) => setAddedObject(event.target.value)}
              >
                <option value="">Select a Salesforce object…</option>
                {availableObjects.map((object) => (
                  <option
                    key={object.salesforce_object}
                    value={object.salesforce_object}
                  >
                    {object.label} ({object.salesforce_object})
                    {object.custom ? ' — custom' : ''}
                  </option>
                ))}
              </select>
            </div>

            <SyncPanel
              syncRuns={sync_runs}
              hasEnabledMapping={object_mappings.some((mapping) => mapping.enabled)}
              syncUrl={`${basePath}/sync`}
            />
          </div>
        )}
      </section>
    </div>
  )
}

export default SalesforceShow
