import { AlertTriangle, Plus, X } from 'lucide-react'

import type { ContextLevel } from '@/lib/woofed_ai'

interface SessionAlertProps {
  level: Exclude<ContextLevel, 'off'>
  pct: number
  onNewSession: () => void
  onDismiss?: () => void
}

// Per-level styling. Critical uses the danger feedback tokens; the warning uses
// the amber palette (the design system has no semantic "warning" yet).
const STYLES = {
  warn: {
    container: 'border-amber-300 bg-amber-50',
    icon: 'text-amber-500',
    title: 'text-amber-800',
    desc: 'text-amber-700',
    bar: 'bg-amber-500',
    button: 'bg-amber-500 hover:bg-amber-600',
    dismiss: 'text-amber-700'
  },
  crit: {
    container: 'color-border-feedback-danger-default color-bg-feedback-danger-default',
    icon: 'color-fg-feedback-danger',
    title: 'text-red-700',
    desc: 'text-red-600',
    bar: 'color-bg-feedback-danger-hard',
    button: 'color-bg-feedback-danger-hard hover:bg-red-600',
    dismiss: 'text-red-600'
  }
} as const

const COPY = {
  warn: {
    title: 'This conversation is getting long',
    desc: 'Long conversations make the assistant forget earlier details. Consider starting a new session.'
  },
  crit: {
    title: 'Context limit almost reached',
    desc: 'Woofed AI may no longer remember the start of the conversation. Start a new session to keep replies accurate.'
  }
}

// Warns the user as the conversation approaches the agent's history window, with
// a context meter and a one-click "new session" action. Critical alerts cannot
// be dismissed; warnings can.
const SessionAlert = ({ level, pct, onNewSession, onDismiss }: SessionAlertProps) => {
  const s = STYLES[level]
  const copy = COPY[level]

  return (
    <div className="mx-auto mb-2.5 max-w-[740px] animate-in fade-in slide-in-from-bottom-1">
      <div
        className={`flex items-start gap-3 rounded-[10px] border-[1.5px] px-3 py-2.5 ${s.container}`}
      >
        <span className="mt-px flex size-[26px] shrink-0 items-center justify-center rounded-md color-bg-surface-default">
          <AlertTriangle className={`size-[15px] ${s.icon}`} />
        </span>
        <div className="flex min-w-0 flex-1 flex-col gap-1.5">
          <div className="flex flex-wrap items-center gap-2">
            <span className={`text-subtext font-extrabold ${s.title}`}>
              {copy.title}
            </span>
            <span
              className={`shrink-0 rounded-full color-bg-surface-default px-1.5 py-px text-[11px] font-extrabold ${s.icon}`}
            >
              {pct}%
            </span>
          </div>
          <p className={`typography-micro-m leading-snug ${s.desc}`}>
            {copy.desc}
          </p>
          <div className="mt-0.5 h-1 overflow-hidden rounded-full bg-black/10">
            <div
              className={`h-full rounded-full transition-[width] duration-500 ${s.bar}`}
              style={{ width: `${pct}%` }}
            />
          </div>
        </div>
        <div className="flex shrink-0 items-center gap-1">
          <button
            type="button"
            onClick={onNewSession}
            className={`flex h-8 items-center gap-1.5 rounded-md px-3 text-micro font-bold color-fg-inverse ${s.button}`}
          >
            <Plus className="size-3.5" />
            New session
          </button>
          {level === 'warn' && onDismiss && (
            <button
              type="button"
              onClick={onDismiss}
              title="Dismiss"
              className={`flex size-7 items-center justify-center rounded-md ${s.dismiss}`}
            >
              <X className="size-[15px]" />
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

export default SessionAlert
