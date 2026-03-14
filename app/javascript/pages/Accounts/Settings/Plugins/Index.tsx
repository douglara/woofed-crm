import { router } from '@inertiajs/react'
import {
  Bot,
  CheckCircle2,
  ChevronRight,
  Clock,
  Loader2,
  PlusCircle,
  Sparkles,
  Trash2,
  XCircle,
} from 'lucide-react'
import { animate, stagger } from 'motion'
import { useEffect, useRef } from 'react'

import { cn } from '@/lib/utils'
import PluginShell from './PluginShell'

function getCsrfToken(): string {
  return (
    document
      .querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
      ?.getAttribute('content') ?? ''
  )
}

interface Plugin {
  id: number
  name: string
  description: string | null
  prompt: string
  status: 'pending' | 'building' | 'ready' | 'error'
  created_at: string
  updated_at: string
}

interface Props {
  plugins: Plugin[]
  current_account: { id: number; name: string }
}

const STATUS_CONFIG = {
  pending: {
    label: 'Aguardando',
    icon: Clock,
    className: 'color-bg-feedback-neutral color-fg-feedback-neutral border color-border-hard',
    dotClass: 'bg-dark-gray-palette-p4',
  },
  building: {
    label: 'Construindo',
    icon: Loader2,
    className: 'color-bg-feedback-info-default color-fg-feedback-info border color-border-feedback-info',
    dotClass: 'bg-auxiliary-palette-blue animate-pulse',
  },
  ready: {
    label: 'Pronto',
    icon: CheckCircle2,
    className: 'color-bg-feedback-success-default color-fg-feedback-success border color-border-feedback-success-default',
    dotClass: 'bg-auxiliary-palette-green',
  },
  error: {
    label: 'Erro',
    icon: XCircle,
    className: 'color-bg-feedback-danger-default color-fg-feedback-danger border color-border-feedback-danger-default',
    dotClass: 'bg-auxiliary-palette-red',
  },
}

function StatusBadge({ status }: { status: Plugin['status'] }) {
  const config = STATUS_CONFIG[status] ?? STATUS_CONFIG.pending
  const Icon = config.icon
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full typography-micro-m-lh150',
        config.className,
      )}
    >
      <span className={cn('w-1.5 h-1.5 rounded-full', config.dotClass)} />
      <Icon className={cn('w-3 h-3', status === 'building' && 'animate-spin')} />
      {config.label}
    </span>
  )
}

function EmptyState({ accountId }: { accountId: number }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 px-8 text-center">
      <div className="relative mb-6">
        <div className="w-20 h-20 rounded-2xl bg-brand-palette-07 border-2 border-brand-palette-06 flex items-center justify-center">
          <Bot className="w-10 h-10 text-brand-palette-03" />
        </div>
        <div className="absolute -top-1 -right-1 w-7 h-7 rounded-xl bg-brand-palette-03 flex items-center justify-center">
          <Sparkles className="w-3.5 h-3.5 text-white" />
        </div>
      </div>
      <h3 className="typography-body-s-lh150 text-dark-gray-palette-p1 mb-2">Nenhum plugin ainda</h3>
      <p className="typography-sub-text-r-lh150 text-dark-gray-palette-p3 max-w-sm mb-8">
        Crie seu primeiro plugin com IA. Descreva o que você precisa e a IA vai
        construir automaticamente para você.
      </p>
      <button
        onClick={() => router.visit(`/accounts/${accountId}/settings/plugins/new`)}
        className="btn-primary flex items-center gap-2"
      >
        <PlusCircle className="w-4 h-4" />
        Criar primeiro plugin
      </button>
    </div>
  )
}

export default function PluginsIndex({ plugins, current_account }: Props) {
  const listRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (listRef.current && plugins.length > 0) {
      animate(
        listRef.current.querySelectorAll('[data-card]'),
        { opacity: [0, 1], y: [16, 0] },
        { duration: 0.4, delay: stagger(0.07), easing: 'ease-out' },
      )
    }
  }, [plugins.length])

  const settingsUrl = `/accounts/${current_account.id}/settings`

  return (
    <PluginShell settingsUrl={settingsUrl}>
      <div className="p-6 md:p-8 h-full overflow-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="typography-body-s-lh150 text-dark-gray-palette-p1 mb-0.5">Plugins</h1>
            <p className="typography-sub-text-r-lh150 text-dark-gray-palette-p3">
              Extensões criadas por IA para o seu CRM
            </p>
          </div>
          {plugins.length > 0 && (
            <button
              onClick={() =>
                router.visit(`/accounts/${current_account.id}/settings/plugins/new`)
              }
              className="btn-primary flex items-center gap-2"
            >
              <PlusCircle className="w-4 h-4" />
              Novo Plugin
            </button>
          )}
        </div>

        {plugins.length === 0 ? (
          <EmptyState accountId={current_account.id} />
        ) : (
          <div ref={listRef} className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {plugins.map((plugin) => (
              <div
                key={plugin.id}
                data-card
                className="group relative bg-light-palette-p5 rounded-md border-2 border-light-palette-p3 p-5 hover:border-brand-palette-04 hover:bg-brand-palette-08 transition-all duration-200 cursor-pointer"
                onClick={() =>
                  router.visit(
                    `/accounts/${current_account.id}/settings/plugins/${plugin.id}`,
                  )
                }
              >
                <div className="flex items-start justify-between mb-3">
                  <div className="w-10 h-10 rounded-xl bg-brand-palette-07 border border-brand-palette-06 flex items-center justify-center flex-shrink-0">
                    <Bot className="w-5 h-5 text-brand-palette-03" />
                  </div>
                  <div className="flex items-center gap-2">
                    <StatusBadge status={plugin.status} />
                    <button
                      className="opacity-0 group-hover:opacity-100 transition-opacity duration-200 button-default-blank-secondary-icon-only-sm"
                      onClick={async (e) => {
                        e.stopPropagation()
                        if (!confirm(`Remover plugin "${plugin.name}"?`)) return
                        await fetch(
                          `/accounts/${current_account.id}/settings/plugins/${plugin.id}`,
                          { method: 'DELETE', headers: { 'X-CSRF-Token': getCsrfToken() } },
                        )
                        window.location.reload()
                      }}
                    >
                      <Trash2 className="w-3.5 h-3.5 text-auxiliary-palette-red" />
                    </button>
                  </div>
                </div>

                <h3 className="typography-text-m-lh150 text-dark-gray-palette-p1 mb-1 truncate">
                  {plugin.name}
                </h3>
                {plugin.description && (
                  <p className="typography-sub-text-r-lh150 text-dark-gray-palette-p3 line-clamp-2 mb-3">
                    {plugin.description}
                  </p>
                )}

                <div className="bg-light-palette-p3 rounded-md px-3 py-2 mb-3">
                  <p className="typography-micro-m-lh150 text-dark-gray-palette-p3 mb-0.5">Prompt</p>
                  <p className="typography-micro-m-lh150 text-dark-gray-palette-p1 line-clamp-2">
                    {plugin.prompt}
                  </p>
                </div>

                <div className="flex items-center justify-between">
                  <span className="typography-micro-m-lh150 text-dark-gray-palette-p3">
                    {new Date(plugin.created_at).toLocaleDateString('pt-BR', {
                      day: '2-digit',
                      month: 'short',
                      year: 'numeric',
                    })}
                  </span>
                  <ChevronRight className="w-4 h-4 text-dark-gray-palette-p4 group-hover:text-brand-palette-03 group-hover:translate-x-0.5 transition-all duration-200" />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </PluginShell>
  )
}
