import { RefreshCw } from 'lucide-react'

import { Spinner } from '@/components/ui/spinner'
import { usePendingVisit } from '@/components/salesforce/use-pending-visit'
import type { SyncRun } from '@/types/salesforce'

interface SyncPanelProps {
  syncRuns: SyncRun[]
  hasEnabledMapping: boolean
  syncUrl: string
  syncing: boolean
}

const STATUS_LABELS: Record<SyncRun['status'], string> = {
  pending: 'Queued',
  running: 'Running',
  completed: 'Completed',
  failed: 'Failed'
}

const isUnfinished = (run: SyncRun) =>
  run.status === 'pending' || run.status === 'running'

const SyncPanel = ({
  syncRuns,
  hasEnabledMapping,
  syncUrl,
  syncing
}: SyncPanelProps) => {
  const { isPending, visit } = usePendingVisit()
  const starting = isPending(syncUrl)

  return (
    <section className="rounded-md border color-border-default color-bg-surface-default">
      <header className="flex flex-wrap items-center justify-between gap-4 border-b color-border-default px-6 py-5">
        {/* The text is what gives way when the row runs out of room, so the
            button keeps the corner it started in. */}
        <div className="flex min-w-0 flex-1 flex-col gap-1">
          <h2 className="typography-sub-title-900 color-fg-hard">Initial load</h2>
          <p className="typography-body-900 color-fg-soft">
            Downloads everything the enabled objects have. Later changes arrive on
            their own.
          </p>
        </div>

        {/* Only the icon changes while the request is in flight: a label that
            grew or shrank would move the button under the pointer. */}
        <button
          type="button"
          disabled={!hasEnabledMapping || starting}
          onClick={() => visit(syncUrl)}
          className="button-default-fill-primary-md disabled:opacity-50"
        >
          {starting ? <Spinner /> : <RefreshCw />}
          Sync now
        </button>
      </header>

      <div className="flex flex-col gap-3 px-6 py-5">
        {!hasEnabledMapping && (
          <p className="typography-body-900 color-fg-extra-soft">
            Enable at least one object above to run the initial load.
          </p>
        )}

        {/* Below the header rather than beside the button: a badge that appears
            and disappears next to it would push it onto a line of its own. */}
        {syncing && (
          <span className="flex items-center gap-2 typography-body-900 color-fg-soft">
            <Spinner />
            Updating live
          </span>
        )}

        {syncRuns.map((run) => (
          <div key={run.id} className="flex flex-wrap items-center justify-between gap-3">
            <span className="flex items-center gap-2 typography-body-900 color-fg-default">
              {isUnfinished(run) && <Spinner />}
              {run.salesforce_object}
            </span>
            <span className="typography-body-900 color-fg-soft">
              {STATUS_LABELS[run.status]} · {run.records_downloaded} records
            </span>
            {run.error && (
              <span className="typography-body-900 color-fg-feedback-danger">
                {run.error}
              </span>
            )}
          </div>
        ))}
      </div>
    </section>
  )
}

export default SyncPanel
