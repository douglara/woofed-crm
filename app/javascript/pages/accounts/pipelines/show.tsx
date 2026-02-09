import { useState, useCallback, useEffect } from 'react'
import { Head, usePage } from '@inertiajs/react'
import {
  DndContext,
  DragEndEvent,
  DragOverlay,
  DragStartEvent,
  PointerSensor,
  useSensor,
  useSensors,
  closestCorners,
} from '@dnd-kit/core'
import { arrayMove } from '@dnd-kit/sortable'
import { StageColumn } from './components/StageColumn'
import { DealCard } from './components/DealCard'
import { usePipelineChannel } from '../../../hooks/usePipelineChannel'
import type { KanbanPageProps, Deal, Stage } from '../../../types/kanban'

interface StageDealsUpdate {
  stage_id: number
  deals: Deal[]
  has_more_deals: boolean
  next_page: number | null
}

interface StageRefresh extends Stage {}

interface PageProps extends KanbanPageProps {
  stage_deals?: StageDealsUpdate
  stage_refresh?: StageRefresh
}

export default function PipelineShow({
  pipeline,
  filter_status_deal,
  account_id,
  account_currency,
  user_locale,
}: KanbanPageProps) {
  const { props } = usePage<PageProps>()
  const [stages, setStages] = useState<Stage[]>(pipeline.stages)
  const [activeDeal, setActiveDeal] = useState<Deal | null>(null)

  // Get the number of deals currently loaded for a stage (for buffer maintenance)
  const getStageDealsCount = useCallback((stageId: number): number => {
    const stage = stages.find((s) => s.id === stageId)
    return stage ? stage.deals.length : 0
  }, [stages])

  // Subscribe to real-time updates via ActionCable
  usePipelineChannel(pipeline.id, {
    accountId: account_id,
    filterStatusDeal: filter_status_deal,
    getStageDealsCount,
  })

  // Handle incoming stage_deals updates from infinite scroll
  useEffect(() => {
    if (props.stage_deals) {
      const { stage_id, deals: newDeals, has_more_deals, next_page } = props.stage_deals

      setStages((prev) =>
        prev.map((stage) => {
          if (stage.id === stage_id) {
            // Merge new deals, avoiding duplicates
            const existingIds = new Set(stage.deals.map((d) => d.id))
            const uniqueNewDeals = newDeals.filter((d) => !existingIds.has(d.id))

            return {
              ...stage,
              deals: [...stage.deals, ...uniqueNewDeals],
              has_more_deals,
              next_page,
            }
          }
          return stage
        })
      )
    }
  }, [props.stage_deals])

  // Handle incoming stage_refresh updates from real-time channel
  useEffect(() => {
    if (props.stage_refresh) {
      const refreshedStage = props.stage_refresh

      setStages((prev) =>
        prev.map((stage) => {
          if (stage.id === refreshedStage.id) {
            return refreshedStage
          }
          return stage
        })
      )
    }
  }, [props.stage_refresh])

  // Reset stages when pipeline changes
  useEffect(() => {
    setStages(pipeline.stages)
  }, [pipeline.id])

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  )

  const findDealById = useCallback((id: number): Deal | null => {
    for (const stage of stages) {
      const deal = stage.deals.find((d) => d.id === id)
      if (deal) return deal
    }
    return null
  }, [stages])

  const findStageByDealId = useCallback((dealId: number): Stage | null => {
    return stages.find((stage) => stage.deals.some((d) => d.id === dealId)) || null
  }, [stages])

  const handleDragStart = useCallback((event: DragStartEvent) => {
    const dealId = event.active.id as number
    const deal = findDealById(dealId)
    setActiveDeal(deal)
    document.body.classList.add('is-dragging')
  }, [findDealById])

  const handleDragEnd = useCallback(async (event: DragEndEvent) => {
    const { active, over } = event
    document.body.classList.remove('is-dragging')
    setActiveDeal(null)

    if (!over) return

    const dealId = active.id as number
    const sourceStage = findStageByDealId(dealId)
    if (!sourceStage) return

    let targetStageId: number
    let targetDealId: number | null = null

    if (String(over.id).startsWith('stage-')) {
      targetStageId = parseInt(String(over.id).replace('stage-', ''))
    } else {
      targetDealId = over.id as number
      const targetStage = findStageByDealId(targetDealId)
      if (!targetStage) return
      targetStageId = targetStage.id
    }

    const targetStage = stages.find((s) => s.id === targetStageId)
    if (!targetStage) return

    // Calculate new position
    let newPosition: number
    if (sourceStage.id === targetStageId) {
      // Moving within the same stage
      const oldIndex = sourceStage.deals.findIndex((d) => d.id === dealId)
      const newIndex = targetDealId
        ? targetStage.deals.findIndex((d) => d.id === targetDealId)
        : targetStage.deals.length

      if (oldIndex === newIndex) return

      const movedDeals = arrayMove(sourceStage.deals, oldIndex, newIndex)
      const referenceDeals = movedDeals.filter((d) => d.id !== dealId)

      if (newIndex === 0) {
        newPosition = referenceDeals[0]?.position ? referenceDeals[0].position + 1 : 1
      } else if (newIndex >= referenceDeals.length) {
        newPosition = referenceDeals[referenceDeals.length - 1]?.position
          ? referenceDeals[referenceDeals.length - 1].position - 1
          : 1
      } else {
        newPosition = referenceDeals[newIndex]?.position || 1
      }

      setStages((prev) =>
        prev.map((stage) => {
          if (stage.id === sourceStage.id) {
            return { ...stage, deals: movedDeals }
          }
          return stage
        })
      )
    } else {
      // Moving to a different stage
      const deal = sourceStage.deals.find((d) => d.id === dealId)!
      const newIndex = targetDealId
        ? targetStage.deals.findIndex((d) => d.id === targetDealId)
        : 0

      if (newIndex === 0 || targetStage.deals.length === 0) {
        newPosition = targetStage.deals[0]?.position
          ? targetStage.deals[0].position + 1
          : 1
      } else {
        newPosition = targetStage.deals[newIndex - 1]?.position
          ? targetStage.deals[newIndex - 1].position - 1
          : 1
      }

      setStages((prev) =>
        prev.map((stage) => {
          if (stage.id === sourceStage.id) {
            return {
              ...stage,
              deals: stage.deals.filter((d) => d.id !== dealId),
            }
          }
          if (stage.id === targetStageId) {
            const newDeals = [...stage.deals]
            newDeals.splice(newIndex, 0, { ...deal, position: newPosition })
            return { ...stage, deals: newDeals }
          }
          return stage
        })
      )
    }

    // Send update to server
    try {
      const formData = new FormData()
      formData.append('deal[position]', String(newPosition))
      formData.append('deal[stage_id]', String(targetStageId))

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

      await fetch(`/accounts/${account_id}/deals/${dealId}`, {
        method: 'PATCH',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-CSRF-Token': csrfToken || '',
        },
        body: formData,
      })
    } catch (error) {
      console.error('Error updating deal position:', error)
      // Revert optimistic update on error
      setStages(pipeline.stages)
    }
  }, [stages, findStageByDealId, account_id, pipeline.stages])

  return (
    <>
      <Head title={`${pipeline.name} - Kanban`} />

      <DndContext
        sensors={sensors}
        collisionDetection={closestCorners}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <div data-controller="lists" data-lists-id={pipeline.id}>
          <section className="p-8 grid grid-flow-col auto-cols-[18.75rem] gap-5" style={{ minWidth: 'max-content' }}>
            {stages.map((stage) => (
              <StageColumn
                key={stage.id}
                stage={stage}
                accountId={account_id}
                pipelineId={pipeline.id}
                filterStatusDeal={filter_status_deal}
                currency={account_currency}
                locale={user_locale}
              />
            ))}
          </section>
        </div>

        <DragOverlay>
          {activeDeal && (
            <DealCard
              deal={activeDeal}
              accountId={account_id}
              currency={account_currency}
              locale={user_locale}
              isDragging
            />
          )}
        </DragOverlay>
      </DndContext>
    </>
  )
}
