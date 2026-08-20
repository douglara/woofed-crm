import { useState } from 'react'
import { router } from '@inertiajs/react'
import type { VisitOptions } from '@inertiajs/core'

/**
 * A visit that the button which started it waits for.
 *
 * Every action on this screen sets background work going — a backfill, a retry,
 * a saved mapping — and none of them answer instantly. A second click before the
 * answer lands starts that work twice.
 *
 * What is pending is tracked by url rather than as a flag, because a list of
 * retry buttons has to show which row is waiting, not merely that something is.
 */
export const usePendingVisit = () => {
  const [pendingUrl, setPendingUrl] = useState<string | null>(null)

  // Scroll and local state are held on purpose: these buttons sit far down a
  // long screen, beside field pickers the user has open.
  const visit = (url: string, options: VisitOptions = {}) =>
    router.visit(url, {
      method: 'post',
      preserveScroll: true,
      preserveState: true,
      ...options,
      onStart: () => setPendingUrl(url),
      onFinish: () => setPendingUrl(null)
    })

  const isPending = (url?: string) =>
    url === undefined ? pendingUrl !== null : pendingUrl === url

  return { isPending, visit }
}
