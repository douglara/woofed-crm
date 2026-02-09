import { useEffect, useRef } from 'react'
import { router } from '@inertiajs/react'
import consumer from '../channels/consumer'
import type { Stage } from '../types/kanban'

interface PipelineMessage {
  type: string
  stage_id: number
  pipeline_id: number
  updated_at: number
}

interface UsePipelineChannelOptions {
  accountId: number
  filterStatusDeal: string
  getStageDealsCount: (stageId: number) => number
}

export function usePipelineChannel(
  pipelineId: number,
  options: UsePipelineChannelOptions
) {
  const subscriptionRef = useRef<any>(null)
  const pendingUpdatesRef = useRef<Set<number>>(new Set())
  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null)

  useEffect(() => {
    subscriptionRef.current = consumer.subscriptions.create(
      { channel: 'PipelineChannel', pipeline_id: pipelineId },
      {
        received(data: PipelineMessage) {
          if (data.type === 'stage_updated') {
            // Add stage to pending updates
            pendingUpdatesRef.current.add(data.stage_id)

            // Debounce: wait 500ms before refreshing to batch multiple updates
            if (debounceTimerRef.current) {
              clearTimeout(debounceTimerRef.current)
            }

            debounceTimerRef.current = setTimeout(async () => {
              const stageIds = Array.from(pendingUpdatesRef.current)
              pendingUpdatesRef.current.clear()

              // Refresh each stage sequentially to avoid Inertia canceling requests
              for (const stageId of stageIds) {
                const currentCount = options.getStageDealsCount(stageId)

                await new Promise<void>((resolve) => {
                  router.get(
                    `/accounts/${options.accountId}/pipelines/${pipelineId}/refresh_stage`,
                    {
                      stage_id: stageId,
                      filter_status_deal: options.filterStatusDeal,
                      current_count: currentCount,
                    },
                    {
                      preserveState: true,
                      preserveScroll: true,
                      only: ['stage_refresh'],
                      onFinish: () => resolve(),
                    }
                  )
                })
              }
            }, 500)
          }
        },

        connected() {
          console.log(`Connected to pipeline channel: ${pipelineId}`)
        },

        disconnected() {
          console.log(`Disconnected from pipeline channel: ${pipelineId}`)
        },
      }
    )

    return () => {
      if (subscriptionRef.current) {
        subscriptionRef.current.unsubscribe()
      }
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current)
      }
    }
  }, [pipelineId, options.accountId, options.filterStatusDeal, options.getStageDealsCount])
}
