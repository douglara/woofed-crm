import { router, usePoll } from '@inertiajs/react'
import {
  ArrowLeft,
  Bot,
  Calendar,
  CheckCircle2,
  Clock,
  GitBranch,
  Link,
  Loader2,
  RefreshCw,
  Trash2,
  XCircle,
  Zap,
} from 'lucide-react'
import { useEffect, useRef, useState } from 'react'

import { cn } from '@/lib/utils'
import AgentPluginBuilderShell from './AgentPluginBuilderShell'

interface AgentPluginBuilder {
  id: number
  name: string
  description: string | null
  status: 'pending' | 'processing' | 'completed' | 'failed'
  logs: string | null
  error_message: string | null
  repo_url: string | null
  branch_name: string | null
  created_at: string
  updated_at: string
}

interface Props {
  agent_plugin_builder: AgentPluginBuilder
  current_account: { id: number; name: string }
}

const STATUS_CONFIG = {
  pending: {
    label: 'Pending',
    icon: Clock,
    dot: 'bg-dark-gray-palette-p4',
    className: 'color-bg-feedback-neutral color-fg-feedback-neutral border color-border-hard',
  },
  processing: {
    label: 'Building...',
    icon: Loader2,
    dot: 'bg-auxiliary-palette-blue animate-pulse',
    className: 'color-bg-feedback-info-default color-fg-feedback-info border color-border-feedback-info',
  },
  completed: {
    label: 'Completed',
    icon: CheckCircle2,
    dot: 'bg-auxiliary-palette-green',
    className: 'color-bg-feedback-success-default color-fg-feedback-success border color-border-feedback-success-default',
  },
  failed: {
    label: 'Failed',
    icon: XCircle,
    dot: 'bg-auxiliary-palette-red',
    className: 'color-bg-feedback-danger-default color-fg-feedback-danger border color-border-feedback-danger-default',
  },
}

function getCsrfToken(): string {
  return (
    document
      .querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
      ?.getAttribute('content') ?? ''
  )
}

export default function AgentPluginBuildersShow({ agent_plugin_builder: apb, current_account }: Props) {
  const settingsUrl = `/accounts/${current_account.id}/settings`
  const logEndRef = useRef<HTMLDivElement>(null)
  const isActive = apb.status === 'pending' || apb.status === 'processing'
  const [isRestarting, setIsRestarting] = useState(apb.status === 'completed')

  // Poll the show endpoint every 2s while the build is running.
  // usePoll returns { stop, start } — stop is called when isActive turns false
  // or the component unmounts (cleanup in usePoll's own effect).
  const { stop } = usePoll(2000, {}, { autoStart: isActive, keepAlive: false })

  // Stop polling when build reaches a terminal state
  useEffect(() => {
    if (!isActive) stop()
  }, [isActive, stop])

  // When build completes, poll /up every 2s until the app is back, then redirect
  useEffect(() => {
    if (!isRestarting) return
    let cancelled = false
    const interval = setInterval(async () => {
      try {
        const res = await fetch('/up', { cache: 'no-store' })
        if (res.ok && !cancelled) {
          clearInterval(interval)
          router.visit(settingsUrl)
        }
      } catch {
        // app is still restarting — keep waiting
      }
    }, 2000)
    return () => {
      cancelled = true
      clearInterval(interval)
    }
  }, [isRestarting, settingsUrl])

  // Transition to restarting state when build completes
  useEffect(() => {
    if (apb.status === 'completed') setIsRestarting(true)
  }, [apb.status])

  // Auto-scroll to the bottom as new log lines arrive
  useEffect(() => {
    logEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [apb.logs])

  const statusConfig = isRestarting
    ? { label: 'Installing...', icon: Loader2, dot: 'bg-auxiliary-palette-blue animate-pulse', className: 'color-bg-feedback-info-default color-fg-feedback-info border color-border-feedback-info' }
    : STATUS_CONFIG[apb.status] ?? STATUS_CONFIG.pending
  const StatusIcon = statusConfig.icon

  const handleDelete = async () => {
    if (!confirm(`Are you sure you want to remove "${apb.name}"?`)) return
    await fetch(`/accounts/${current_account.id}/settings/agent_plugin_builders/${apb.id}`, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': getCsrfToken() },
    })
    window.location.href = settingsUrl
  }

  return (
    <AgentPluginBuilderShell settingsUrl={settingsUrl}>
      <div className="flex h-full overflow-hidden">
        {/* ── Left sidebar: info ── */}
        <div className="w-72 flex-shrink-0 border-r-2 border-light-palette-p3 bg-light-palette-p5 flex flex-col overflow-hidden">
          {/* Header */}
          <div className="p-4 border-b-2 border-light-palette-p3">
            <button
              className="flex items-center gap-1.5 typography-micro-m-lh150 text-dark-gray-palette-p3 hover:text-dark-gray-palette-p1 mb-3 group transition-colors"
              onClick={() =>
                router.visit(`/accounts/${current_account.id}/settings/agent_plugin_builders`)
              }
            >
              <ArrowLeft className="w-3.5 h-3.5 group-hover:-translate-x-0.5 transition-transform" />
              Agent Plugin Builders
            </button>
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-brand-palette-07 border border-brand-palette-06 flex items-center justify-center flex-shrink-0">
                <Bot className="w-4 h-4 text-brand-palette-03" />
              </div>
              <div className="min-w-0">
                <h1 className="typography-text-m-lh150 text-dark-gray-palette-p1 truncate">
                  {apb.name}
                </h1>
              </div>
            </div>
          </div>

          {/* Status */}
          <div className="p-4 border-b-2 border-light-palette-p3">
            <p className="typography-micro-m-lh150 text-dark-gray-palette-p3 uppercase tracking-wider mb-2">
              Status
            </p>
            <div
              className={cn(
                'flex items-center gap-2 px-3 py-2 rounded-md typography-micro-m-lh150',
                statusConfig.className,
              )}
            >
              <div className={cn('w-1.5 h-1.5 rounded-full', statusConfig.dot)} />
              <StatusIcon
                className={cn(
                  'w-3.5 h-3.5',
                  (apb.status === 'processing' || isRestarting) && 'animate-spin',
                )}
              />
              {statusConfig.label}
            </div>
          </div>

          {/* Prompt */}
          {apb.description && (
            <div className="p-4 border-b-2 border-light-palette-p3 flex-1 overflow-auto">
              <p className="typography-micro-m-lh150 text-dark-gray-palette-p3 uppercase tracking-wider mb-2">
                Prompt
              </p>
              <p className="typography-sub-text-r-lh150 text-dark-gray-palette-p1">{apb.description}</p>
            </div>
          )}

          {/* Build info */}
          {(apb.repo_url || apb.branch_name) && (
            <div className="p-4 border-b-2 border-light-palette-p3">
              {apb.repo_url && (
                <div className="flex items-center gap-2 typography-micro-m-lh150 text-dark-gray-palette-p3 mb-1">
                  <Link className="w-3.5 h-3.5" />
                  <a
                    href={apb.repo_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="truncate hover:text-brand-palette-03 transition-colors"
                  >
                    Repository
                  </a>
                </div>
              )}
              {apb.branch_name && (
                <div className="flex items-center gap-2 typography-micro-m-lh150 text-dark-gray-palette-p3">
                  <GitBranch className="w-3.5 h-3.5" />
                  <span className="truncate">{apb.branch_name}</span>
                </div>
              )}
            </div>
          )}

          {/* Meta + actions */}
          <div className="p-4 flex flex-col gap-2 mt-auto">
            <div className="flex items-center gap-2 typography-micro-m-lh150 text-dark-gray-palette-p3">
              <Calendar className="w-3.5 h-3.5" />
              {new Date(apb.created_at).toLocaleDateString('en-US', {
                day: '2-digit',
                month: 'short',
                year: 'numeric',
              })}
            </div>
            <div className="flex items-center gap-2 typography-micro-m-lh150 text-dark-gray-palette-p3">
              <RefreshCw className="w-3.5 h-3.5" />
              {new Date(apb.updated_at).toLocaleDateString('en-US', {
                day: '2-digit',
                month: 'short',
                year: 'numeric',
              })}
            </div>
            <button
              onClick={handleDelete}
              className="flex items-center gap-2 typography-micro-m-lh150 text-auxiliary-palette-red hover:bg-auxiliary-palette-red-down px-3 py-1.5 rounded-md transition-colors mt-1"
            >
              <Trash2 className="w-3.5 h-3.5" />
              Remove
            </button>
          </div>
        </div>

        {/* ── Right: build output ── */}
        <div className="flex-1 flex flex-col overflow-hidden bg-light-palette-p4">
          {/* Header */}
          <div className="flex items-center gap-3 px-5 py-3 border-b-2 border-light-palette-p3 bg-light-palette-p5">
            <div className="w-8 h-8 rounded-md bg-brand-palette-03 flex items-center justify-center">
              <Zap className="w-4 h-4 text-white" />
            </div>
            <div className="flex-1">
              <p className="typography-text-m-lh150 text-dark-gray-palette-p1">
                Build Output
              </p>
              <p className="typography-micro-m-lh150 text-dark-gray-palette-p3 flex items-center gap-1">
                {isActive ? (
                  <>
                    {[0, 1, 2].map((i) => (
                      <span
                        key={i}
                        className="inline-block w-1 h-1 rounded-full bg-brand-palette-03 animate-bounce"
                        style={{ animationDelay: `${i * 150}ms` }}
                      />
                    ))}
                    <span className="ml-0.5 text-brand-palette-03">Running opencode...</span>
                  </>
                ) : isRestarting ? (
                  <>
                    <Loader2 className="w-3 h-3 animate-spin text-auxiliary-palette-blue" />
                    <span className="text-auxiliary-palette-blue">Installing plugin... waiting for the system to restart</span>
                  </>
                ) : apb.status === 'completed' ? (
                  <>
                    <span className="w-1.5 h-1.5 rounded-full bg-auxiliary-palette-green inline-block" />
                    Build completed
                  </>
                ) : (
                  <>
                    <span className="w-1.5 h-1.5 rounded-full bg-auxiliary-palette-red inline-block" />
                    Build failed
                  </>
                )}
              </p>
            </div>
          </div>

          {/* Log output */}
          <div className="flex-1 overflow-auto p-5">
            {apb.logs ? (
              <pre className="typography-micro-m-lh150 text-dark-gray-palette-p1 whitespace-pre-wrap break-words font-mono leading-relaxed">
                {apb.logs}
                {isActive && (
                  <span className="inline-block w-2 h-3.5 bg-brand-palette-03 animate-pulse ml-0.5 align-text-bottom" />
                )}
              </pre>
            ) : (
              <div className="flex flex-col items-center justify-center h-full text-center">
                <Loader2 className="w-8 h-8 text-brand-palette-03 animate-spin mb-3" />
                <p className="typography-sub-text-r-lh150 text-dark-gray-palette-p3">
                  Waiting for the build to start...
                </p>
              </div>
            )}
            <div ref={logEndRef} />
          </div>
        </div>
      </div>
    </AgentPluginBuilderShell>
  )
}
