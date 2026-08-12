import { Head, usePage } from '@inertiajs/react'

import ConnectForm from '@/components/salesforce/ConnectForm'
import ConnectionSummary from '@/components/salesforce/ConnectionSummary'
import ObjectMappingCard from '@/components/salesforce/ObjectMappingCard'
import type {
  ObjectMapping,
  SalesforceConnection,
  SyncableObject,
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
}

const SalesforceShow = ({
  connection,
  callback_url,
  scopes,
  syncable_objects,
  woofed_models,
  woofed_fields,
  object_mappings
}: SalesforceShowProps) => {
  const { current_account } = usePage().props
  const basePath = `/accounts/${current_account.id}/apps/salesforce`

  const mappingFor = (salesforceObject: string) =>
    object_mappings.find(
      (mapping) => mapping.salesforce_object === salesforceObject
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
                Nothing syncs until an object is mapped and enabled.
              </p>
            </div>

            {syncable_objects.map((syncableObject) => (
              <ObjectMappingCard
                key={syncableObject.salesforce_object}
                syncableObject={syncableObject}
                mapping={mappingFor(syncableObject.salesforce_object)}
                woofedModels={woofed_models}
                woofedFields={woofed_fields}
                describeUrl={(salesforceObject) =>
                  `${basePath}/describe/${salesforceObject}`
                }
                submitUrl={`${basePath}/object_mappings`}
              />
            ))}
          </div>
        )}
      </section>
    </div>
  )
}

export default SalesforceShow
