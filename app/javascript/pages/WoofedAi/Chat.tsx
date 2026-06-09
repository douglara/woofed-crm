import { useMemo } from 'react'
import { Head } from '@inertiajs/react'

import { ChatProvider } from '@/components/woofed_ai/ChatContext'
import ChatArea from '@/components/woofed_ai/ChatArea'
import NewSessionButton from '@/components/woofed_ai/NewSessionButton'
import { mapRunsToMessages } from '@/lib/woofed_ai'
import type { SessionRun } from '@/types/woofed_ai'

interface ChatPageProps {
  session_id: string | null
  initial_runs: SessionRun[]
  agent_available: boolean
  model: string | null
  current_account: { id: number; name: string }
}

const ChatPage = ({
  session_id,
  initial_runs,
  agent_available,
  model,
  current_account
}: ChatPageProps) => {
  const initialMessages = useMemo(
    () => mapRunsToMessages(initial_runs ?? []),
    [initial_runs]
  )

  const basePath = `/inertia/accounts/${current_account.id}/woofed_ai`
  const messagesUrl = `${basePath}/messages`
  const sessionsUrl = `${basePath}/sessions`

  return (
    <div className="flex h-full flex-col bg-background">
      <Head title="Woofed AI" />
      <header className="flex items-center justify-between border-b color-border-default px-4 py-3">
        <div className="flex flex-col">
          <h1 className="text-base font-semibold text-foreground">Woofed AI</h1>
          {model && (
            <span className="text-xs text-muted-foreground">{model}</span>
          )}
        </div>
        <NewSessionButton sessionsUrl={sessionsUrl} />
      </header>

      {agent_available ? (
        <div className="min-h-0 flex-1">
          <ChatProvider sessionId={session_id} initialMessages={initialMessages}>
            <ChatArea apiUrl={messagesUrl} />
          </ChatProvider>
        </div>
      ) : (
        <div className="flex flex-1 flex-col items-center justify-center gap-2 px-4 text-center">
          <p className="text-base font-semibold text-foreground">
            Woofed AI is not available yet
          </p>
          <p className="max-w-md text-sm text-muted-foreground">
            Enable the AI assistant and set a model and API key in the company
            settings, then make sure the Woofed AI service is running.
          </p>
        </div>
      )}
    </div>
  )
}

export default ChatPage
