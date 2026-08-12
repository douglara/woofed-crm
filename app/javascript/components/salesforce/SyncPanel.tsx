import { router } from '@inertiajs/react'
import { RefreshCw } from 'lucide-react'

import type { SyncRun } from '@/types/salesforce'

interface SyncPanelProps {
  syncRuns: SyncRun[]
  hasEnabledMapping: boolean
  syncUrl: string
}

const STATUS_LABELS: Record<SyncRun['status'], string> = {
  pending: 'Queued',
  running: 'Running',
  completed: 'Completed',
  failed: 'Failed'
}

const SyncPanel = ({ syncRuns, hasEnabledMapping, syncUrl }: SyncPanelProps) => (
  <section className="rounded-md border color-border-default color-bg-surface-default">
    <header className="flex flex-wrap items-center justify-between gap-4 border-b color-border-default px-6 py-5">
      <div className="flex flex-col gap-1">
        <h2 className="typography-sub-title-900 color-fg-hard">Initial load</h2>
        <p className="typography-body-900 color-fg-soft">
          Downloads everything the enabled objects have. Later changes arrive on
          their own.
        </p>
      </div>

      <button
        type="button"
        disabled={!hasEnabledMapping}
        onClick={() => router.post(syncUrl)}
        className="button-default-fill-primary-md disabled:opacity-50"
      >
        <RefreshCw />
        Sync now
      </button>
    </header>

    <div className="flex flex-col gap-3 px-6 py-5">
      {!hasEnabledMapping && (
        <p className="typography-body-900 color-fg-extra-soft">
          Enable at least one object above to run the initial load.
        </p>
      )}

      {syncRuns.map((run) => (
        <div key={run.id} className="flex flex-wrap items-center justify-between gap-3">
          <span className="typography-body-900 color-fg-default">
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

export default SyncPanel
