import { router } from '@inertiajs/react'
import { TextStreamChatTransport } from 'ai'
import { useChat } from '@ai-sdk/react'
import {
  ArrowLeft,
  Bot,
  Calendar,
  CheckCircle2,
  Clock,
  Loader2,
  RefreshCw,
  Trash2,
  User,
  XCircle,
  Zap,
} from 'lucide-react'
import { useState } from 'react'

import {
  Conversation,
  ConversationContent,
  ConversationScrollButton,
} from '@/components/ai-elements/conversation'
import {
  Message,
  MessageContent,
  MessageResponse,
} from '@/components/ai-elements/message'
import type { PromptInputMessage } from '@/components/ai-elements/prompt-input'
import {
  PromptInput,
  PromptInputBody,
  PromptInputFooter,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputTools,
} from '@/components/ai-elements/prompt-input'
import { cn } from '@/lib/utils'
import PluginShell from './PluginShell'

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
  plugin: Plugin
  current_account: { id: number; name: string }
}

const STATUS_CONFIG = {
  pending: {
    label: 'Aguardando',
    icon: Clock,
    dot: 'bg-dark-gray-palette-p4',
    className: 'color-bg-feedback-neutral color-fg-feedback-neutral border color-border-hard',
  },
  building: {
    label: 'Construindo...',
    icon: Loader2,
    dot: 'bg-auxiliary-palette-blue animate-pulse',
    className: 'color-bg-feedback-info-default color-fg-feedback-info border color-border-feedback-info',
  },
  ready: {
    label: 'Pronto',
    icon: CheckCircle2,
    dot: 'bg-auxiliary-palette-green',
    className: 'color-bg-feedback-success-default color-fg-feedback-success border color-border-feedback-success-default',
  },
  error: {
    label: 'Erro',
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

export default function PluginsShow({ plugin, current_account }: Props) {
  const chatUrl = `/accounts/${current_account.id}/settings/plugins/${plugin.id}/chat`
  const settingsUrl = `/accounts/${current_account.id}/settings`
  const [input, setInput] = useState('')

  const welcomeText = `Olá! Sou o assistente de IA responsável por construir o plugin **"${plugin.name}"**.\n\nEstou analisando seu prompt e em breve vou apresentar o plano de implementação detalhado. Você pode me fazer perguntas sobre o plugin a qualquer momento.`

  const { messages, sendMessage, status } = useChat({
    messages: [
      {
        id: 'welcome',
        role: 'assistant' as const,
        content: welcomeText,
        parts: [{ type: 'text' as const, text: welcomeText }],
      },
    ],
    transport: new TextStreamChatTransport({
      api: chatUrl,
      headers: { 'X-CSRF-Token': getCsrfToken() },
    }),
  })

  const isLoading = status === 'streaming' || status === 'submitted'

  const statusConfig = STATUS_CONFIG[plugin.status] ?? STATUS_CONFIG.pending
  const StatusIcon = statusConfig.icon

  const handleSubmit = (msg: PromptInputMessage) => {
    if (!msg.text.trim() || isLoading) return
    sendMessage({ text: msg.text })
    setInput('')
  }

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      if (!isLoading && input.trim()) {
        sendMessage({ text: input })
        setInput('')
      }
    }
  }

  // Delete: use fetch directly to avoid Inertia following the redirect to a Hotwire page
  const handleDelete = async () => {
    if (!confirm(`Tem certeza que deseja remover o plugin "${plugin.name}"?`)) return
    await fetch(`/accounts/${current_account.id}/settings/plugins/${plugin.id}`, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': getCsrfToken() },
    })
    window.location.href = settingsUrl
  }

  return (
    <PluginShell settingsUrl={settingsUrl}>
      <div className="flex h-full overflow-hidden">
        {/* ── Left sidebar: plugin info ── */}
        <div className="w-72 flex-shrink-0 border-r-2 border-light-palette-p3 bg-light-palette-p5 flex flex-col overflow-hidden">
          {/* Plugin header */}
          <div className="p-4 border-b-2 border-light-palette-p3">
            <button
              className="flex items-center gap-1.5 typography-micro-m-lh150 text-dark-gray-palette-p3 hover:text-dark-gray-palette-p1 mb-3 group transition-colors"
              onClick={() =>
                router.visit(`/accounts/${current_account.id}/settings/plugins`)
              }
            >
              <ArrowLeft className="w-3.5 h-3.5 group-hover:-translate-x-0.5 transition-transform" />
              Plugins
            </button>
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-xl bg-brand-palette-07 border border-brand-palette-06 flex items-center justify-center flex-shrink-0">
                <Bot className="w-4 h-4 text-brand-palette-03" />
              </div>
              <div className="min-w-0">
                <h1 className="typography-text-m-lh150 text-dark-gray-palette-p1 truncate">
                  {plugin.name}
                </h1>
                {plugin.description && (
                  <p className="typography-micro-m-lh150 text-dark-gray-palette-p3 mt-0.5 line-clamp-2">
                    {plugin.description}
                  </p>
                )}
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
                  plugin.status === 'building' && 'animate-spin',
                )}
              />
              {statusConfig.label}
            </div>
          </div>

          {/* Prompt */}
          <div className="p-4 border-b-2 border-light-palette-p3 flex-1 overflow-auto">
            <p className="typography-micro-m-lh150 text-dark-gray-palette-p3 uppercase tracking-wider mb-2">
              Prompt
            </p>
            <p className="typography-sub-text-r-lh150 text-dark-gray-palette-p1">{plugin.prompt}</p>
          </div>

          {/* Meta + actions */}
          <div className="p-4 flex flex-col gap-2">
            <div className="flex items-center gap-2 typography-micro-m-lh150 text-dark-gray-palette-p3">
              <Calendar className="w-3.5 h-3.5" />
              {new Date(plugin.created_at).toLocaleDateString('pt-BR', {
                day: '2-digit',
                month: 'short',
                year: 'numeric',
              })}
            </div>
            <div className="flex items-center gap-2 typography-micro-m-lh150 text-dark-gray-palette-p3">
              <RefreshCw className="w-3.5 h-3.5" />
              {new Date(plugin.updated_at).toLocaleDateString('pt-BR', {
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
              Remover plugin
            </button>
          </div>
        </div>

        {/* ── Right: AI chat ── */}
        <div className="flex-1 flex flex-col overflow-hidden bg-light-palette-p4">
          {/* Chat header */}
          <div className="flex items-center gap-3 px-5 py-3 border-b-2 border-light-palette-p3 bg-light-palette-p5">
            <div className="w-8 h-8 rounded-md bg-brand-palette-03 flex items-center justify-center">
              <Zap className="w-4 h-4 text-white" />
            </div>
            <div className="flex-1">
              <p className="typography-text-m-lh150 text-dark-gray-palette-p1">
                IA Construtora de Plugin
              </p>
              <p className="typography-micro-m-lh150 text-dark-gray-palette-p3 flex items-center gap-1">
                {isLoading ? (
                  <>
                    {[0, 1, 2].map((i) => (
                      <span
                        key={i}
                        className="inline-block w-1 h-1 rounded-full bg-brand-palette-03 animate-bounce"
                        style={{ animationDelay: `${i * 150}ms` }}
                      />
                    ))}
                    <span className="ml-0.5 text-brand-palette-03">Gerando resposta...</span>
                  </>
                ) : (
                  <>
                    <span className="w-1.5 h-1.5 rounded-full bg-auxiliary-palette-green inline-block" />
                    Online · pronta para responder
                  </>
                )}
              </p>
            </div>
          </div>

          {/* Messages */}
          <Conversation className="flex-1 min-h-0">
            <ConversationContent className="gap-4 p-5">
              {messages.map((message) => (
                <Message key={message.id} from={message.role}>
                  {message.role === 'assistant' ? (
                    <div className="flex items-start gap-3">
                      <div className="w-8 h-8 rounded-md bg-brand-palette-03 flex items-center justify-center flex-shrink-0">
                        <Bot className="w-4 h-4 text-white" />
                      </div>
                      <MessageContent className="bg-light-palette-p5 rounded-md border-2 border-light-palette-p3 px-4 py-3 max-w-[85%]">
                        <MessageResponse
                          className="typography-sub-text-r-lh150 text-dark-gray-palette-p1"
                          isAnimating={
                            isLoading &&
                            message.id === messages[messages.length - 1]?.id
                          }
                        >
                          {message.parts
                            ?.filter((p) => p.type === 'text')
                            .map((p) => (p as { type: 'text'; text: string }).text)
                            .join('') ?? message.content}
                        </MessageResponse>
                      </MessageContent>
                    </div>
                  ) : (
                    <div className="flex items-start gap-3 justify-end">
                      <MessageContent className="bg-brand-palette-03 text-white rounded-md px-4 py-3 max-w-[75%]">
                        <p className="typography-sub-text-r-lh150 whitespace-pre-wrap">
                          {message.content}
                        </p>
                      </MessageContent>
                      <div className="w-8 h-8 rounded-md bg-brand-palette-07 border border-brand-palette-06 flex items-center justify-center flex-shrink-0">
                        <User className="w-4 h-4 text-brand-palette-03" />
                      </div>
                    </div>
                  )}
                </Message>
              ))}

              {isLoading && messages[messages.length - 1]?.role !== 'assistant' && (
                <Message from="assistant">
                  <div className="flex items-start gap-3">
                    <div className="w-8 h-8 rounded-md bg-brand-palette-03 flex items-center justify-center flex-shrink-0">
                      <Loader2 className="w-4 h-4 text-white animate-spin" />
                    </div>
                    <div className="bg-light-palette-p5 rounded-md border-2 border-light-palette-p3 px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        {[0, 1, 2].map((i) => (
                          <div
                            key={i}
                            className="w-1.5 h-1.5 rounded-full bg-dark-gray-palette-p4 animate-bounce"
                            style={{ animationDelay: `${i * 150}ms` }}
                          />
                        ))}
                      </div>
                    </div>
                  </div>
                </Message>
              )}
            </ConversationContent>
            <ConversationScrollButton />
          </Conversation>

          {/* Input — PromptInput from ai-elements */}
          <div className="border-t-2 border-light-palette-p3 bg-light-palette-p5 px-5 py-4">
            <PromptInput
              isLoading={isLoading}
              onSubmit={handleSubmit}
              className="border-2 border-light-palette-p3 bg-light-palette-p4 focus-within:border-brand-palette-04"
            >
              <PromptInputBody>
                <PromptInputTextarea
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Pergunte sobre o plugin, peça ajustes ou acompanhe o progresso..."
                  className="typography-sub-text-r-lh150 text-dark-gray-palette-p1 placeholder:text-dark-gray-palette-p4"
                />
              </PromptInputBody>
              <PromptInputFooter>
                <PromptInputTools>
                  <p className="typography-micro-m-lh150 text-dark-gray-palette-p4">
                    Enter para enviar · Shift+Enter para nova linha
                  </p>
                </PromptInputTools>
                <PromptInputSubmit
                  disabled={!input.trim() || isLoading}
                  status={status}
                  className="bg-brand-palette-03 hover:bg-brand-palette-02 disabled:bg-light-palette-p3"
                />
              </PromptInputFooter>
            </PromptInput>
          </div>
        </div>
      </div>
    </PluginShell>
  )
}
