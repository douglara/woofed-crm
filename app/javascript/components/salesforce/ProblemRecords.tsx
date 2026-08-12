import { router } from '@inertiajs/react'
import { RotateCcw } from 'lucide-react'

import type { ProblemRecord } from '@/types/salesforce'

interface ProblemRecordsProps {
  records: ProblemRecord[]
  retryUrl: (id: number) => string
}

const STATUS_BADGES: Record<ProblemRecord['status'], { label: string; className: string }> = {
  conflict: {
    label: 'Conflict',
    className: 'color-bg-feedback-info-default color-fg-feedback-info'
  },
  failed: {
    label: 'Failed',
    className: 'color-bg-feedback-danger-default color-fg-feedback-danger'
  }
}

/**
 * The rows that did not make it. Without this list a user only learns that some
 * records are missing, never which ones or why — and a conflict is a decision
 * waiting for them, not an error to retry blindly.
 */
const ProblemRecords = ({ records, retryUrl }: ProblemRecordsProps) => (
  <section className="rounded-md border color-border-default color-bg-surface-default">
    <header className="border-b color-border-default px-6 py-5">
      <h2 className="typography-sub-title-900 color-fg-hard">Rows to review</h2>
      <p className="typography-body-900 color-fg-soft">
        Records Salesforce sent that Woofed could not import as they are.
      </p>
    </header>

    <div className="flex flex-col gap-3 px-6 py-5">
      {records.length === 0 && (
        <p className="typography-body-900 color-fg-extra-soft">
          Every record imported. Nothing to review.
        </p>
      )}

      {records.map((record) => {
        const badge = STATUS_BADGES[record.status]

        return (
          <div
            key={record.id}
            className="flex flex-wrap items-center justify-between gap-3 border-b color-border-default pb-3 last:border-0 last:pb-0"
          >
            <div className="flex flex-col gap-1">
              <div className="flex items-center gap-2">
                <span className="typography-body-900 color-fg-default">
                  {record.salesforce_object}
                </span>
                <code className="typography-body-800 color-fg-extra-soft">
                  {record.salesforce_id}
                </code>
                <span
                  className={`rounded-full px-2 py-0.5 typography-button-800 ${badge.className}`}
                >
                  {badge.label}
                </span>
              </div>
              <span className="typography-body-900 color-fg-soft">{record.error}</span>
            </div>

            <button
              type="button"
              onClick={() => router.post(retryUrl(record.id))}
              className="button-default-outline-secondary-sm"
            >
              <RotateCcw />
              Try again
            </button>
          </div>
        )
      })}
    </div>
  </section>
)

export default ProblemRecords
