import { Spinner } from '@/components/ui/spinner'
import { usePendingVisit } from '@/components/salesforce/use-pending-visit'
import type { SalesforceConnection } from '@/types/salesforce'

interface ConnectionSummaryProps {
  connection: SalesforceConnection
  disconnectUrl: string
}

const STATUS_BADGES: Record<
  SalesforceConnection['status'],
  { label: string; className: string }
> = {
  inactive: {
    label: 'Not connected',
    className: 'color-bg-feedback-neutral color-fg-feedback-neutral'
  },
  active: {
    label: 'Connected',
    className:
      'color-bg-feedback-success-default color-fg-feedback-success'
  },
  syncing: {
    label: 'Syncing',
    className: 'color-bg-feedback-info-default color-fg-feedback-info'
  },
  error: {
    label: 'Needs reconnection',
    className: 'color-bg-feedback-danger-default color-fg-feedback-danger'
  }
}

const ConnectionSummary = ({
  connection,
  disconnectUrl
}: ConnectionSummaryProps) => {
  const { isPending, visit } = usePendingVisit()
  const badge = STATUS_BADGES[connection.status]

  return (
    <section className="rounded-md border color-border-default color-bg-surface-default">
      <div className="flex flex-wrap items-start justify-between gap-4 px-6 py-5">
        <div className="flex flex-col gap-2">
          <div className="flex items-center gap-3">
            <h2 className="typography-sub-title-900 color-fg-hard">
              {connection.environment === 'sandbox'
                ? 'Sandbox org'
                : 'Production org'}
            </h2>
            <span
              className={`rounded-full px-3 py-1 typography-button-800 ${badge.className}`}
            >
              {badge.label}
            </span>
          </div>

          {connection.organization_id && (
            <p className="typography-body-900 color-fg-soft">
              Organization {connection.organization_id}
            </p>
          )}
          {connection.instance_url && (
            <p className="typography-body-900 color-fg-soft">
              {connection.instance_url}
            </p>
          )}
        </div>

        <button
          type="button"
          disabled={isPending(disconnectUrl)}
          onClick={() => {
            if (window.confirm('Disconnect Salesforce? Synced records are kept.')) {
              visit(disconnectUrl, { method: 'delete' })
            }
          }}
          className="button-default-fill-danger-sm disabled:opacity-50"
        >
          {isPending(disconnectUrl) && <Spinner />}
          Disconnect
        </button>
      </div>

      {connection.status === 'error' && (
        <p className="border-t color-border-feedback-danger-default color-bg-feedback-danger-default px-6 py-3 typography-body-900 color-fg-feedback-danger">
          Salesforce refused the stored credentials. Connect again to restore the
          sync.
        </p>
      )}
    </section>
  )
}

export default ConnectionSummary
