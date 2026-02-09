import { useDroppable } from '@dnd-kit/core'
import { SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { router } from '@inertiajs/react'
import { useRef, useEffect, useState } from 'react'
import { Currency } from '../../../../components/formatters/Currency'
import { DealCard } from './DealCard'
import type { Stage } from '../../../../types/kanban'

interface StageColumnProps {
  stage: Stage
  accountId: number
  pipelineId: number
  filterStatusDeal: string
  currency: string
  locale: string
}

export function StageColumn({
  stage,
  accountId,
  pipelineId,
  filterStatusDeal,
  currency,
  locale,
}: StageColumnProps) {
  const [isLoading, setIsLoading] = useState(false)
  const loadMoreRef = useRef<HTMLDivElement>(null)

  const { setNodeRef, isOver } = useDroppable({
    id: `stage-${stage.id}`,
    data: { stageId: stage.id },
  })

  useEffect(() => {
    if (!stage.has_more_deals || !stage.next_page) return

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !isLoading) {
          setIsLoading(true)

          router.get(
            `/accounts/${accountId}/pipelines/${pipelineId}/load_more_deals`,
            {
              stage_id: stage.id,
              page: stage.next_page,
              filter_status_deal: filterStatusDeal,
            },
            {
              preserveState: true,
              preserveScroll: true,
              only: ['stage_deals'],
              onFinish: () => setIsLoading(false),
            }
          )
        }
      },
      { threshold: 0.1 }
    )

    if (loadMoreRef.current) {
      observer.observe(loadMoreRef.current)
    }

    return () => observer.disconnect()
  }, [stage.has_more_deals, stage.next_page, stage.id, accountId, pipelineId, filterStatusDeal, isLoading])

  return (
    <div
      className={`px-4 pb-4 rounded border-2 border-light-palette-p3 bg-light-palette-p5 relative ${
        isOver ? 'border-brand-palette-03' : ''
      }`}
      id={`stage_${stage.id}_${filterStatusDeal}`}
    >
      <div className="pt-2 pb-3.5 flex flex-col gap-1">
        <div className="flex justify-between items-center gap-1.5">
          <h1
            className="typography-text-s-lh150 color-fg-default truncate cursor-default"
            title={stage.name}
          >
            {stage.name}
          </h1>
          <button
            className="button-default-blank-secondary-icon-only-sm"
            type="button"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="1"/>
              <circle cx="19" cy="12" r="1"/>
              <circle cx="5" cy="12" r="1"/>
            </svg>
          </button>
          <div className="p-0 w-6 rounded-tr-lg absolute border-t-2 border-r-2 border-light-palette-p3 left-[285px] bg-light-palette-p5 rotate-45">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-light-palette-p1 -rotate-45 w-5">
              <path d="m9 18 6-6-6-6"/>
            </svg>
          </div>
        </div>

        <div className="flex items-center justify-between gap-1.5">
          <div
            className="typography-body-900 color-fg-default cursor-default truncate"
            title={`${stage.total_amount}`}
          >
            <Currency value={stage.total_amount} currency={currency} />
          </div>
          <p
            className="py-0.5 px-1 typography-button-800 color-bg-fill-hard color-fg-highlight rounded-lg cursor-default"
            title={`${stage.total_quantity}`}
          >
            {stage.total_quantity_resume}
          </p>
        </div>
      </div>

      <SortableContext
        items={stage.deals.map((d) => d.id)}
        strategy={verticalListSortingStrategy}
      >
        <ul
          ref={setNodeRef}
          data-id={stage.id}
          className="space-y-4 overflow-y-auto custom-scroll-list-deal h-[calc(100vh-260px)]"
          id={`deals_stage_${stage.id}`}
        >
          {stage.deals.map((deal) => (
            <DealCard
              key={deal.id}
              deal={deal}
              accountId={accountId}
              currency={currency}
              locale={locale}
            />
          ))}

          {stage.has_more_deals && (
            <div ref={loadMoreRef} className="py-5 flex justify-center">
              {isLoading && (
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-brand-palette-03"></div>
              )}
            </div>
          )}
        </ul>
      </SortableContext>
    </div>
  )
}
