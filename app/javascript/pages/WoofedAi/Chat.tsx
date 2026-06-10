import { useMemo } from 'react'
import { Head, router, usePage } from '@inertiajs/react'

import { ChatProvider } from '@/components/woofed_ai/ChatContext'
import ChatArea from '@/components/woofed_ai/ChatArea'
import ChatHeader from '@/components/woofed_ai/ChatHeader'
import { mapRunsToMessages } from '@/lib/woofed_ai'
import type { SessionRun } from '@/types/woofed_ai'

interface ChatPageProps {
  session_id: string | null
  initial_runs: SessionRun[]
  agent_available: boolean
  model: string | null
}

const ChatPage = ({
  session_id,
  initial_runs,
  agent_available,
  model
}: ChatPageProps) => {
  const { current_account } = usePage().props
  const initialMessages = useMemo(
    () => mapRunsToMessages(initial_runs ?? []),
    [initial_runs]
  )

  const basePath = `/accounts/${current_account.id}/woofed_ai`
  const messagesUrl = `${basePath}/create_message`
  const newSessionUrl = `${basePath}/create_session`
  const aiAssistantSettingsUrl = `/accounts/${current_account.id}/apps/ai_assistent/edit`

  return (
    <div className="flex h-full flex-col bg-light-palette-p4">
      <Head title="Woofed AI" />
      <ChatHeader
        model={agent_available ? model : null}
        onNewConversation={() => router.post(newSessionUrl)}
      />

      {agent_available ? (
        // Key on the session so switching sessions (e.g. "New session")
        // remounts the provider and resets the chat instead of keeping the
        // previous session's messages.
        <ChatProvider
          key={session_id ?? 'none'}
          sessionId={session_id}
          initialMessages={initialMessages}
        >
          <ChatArea apiUrl={messagesUrl} newSessionUrl={newSessionUrl} />
        </ChatProvider>
      ) : (
        <div className="flex flex-1 flex-col items-center justify-center gap-2 px-8 text-center">
          <p className="typography-sub-title-950 color-fg-default">
            Woofed AI is not available yet
          </p>
          <p className="max-w-md typography-body-1000 color-fg-soft">
            Enable the AI assistant and set a model and API key in the{' '}
            <a
              href={aiAssistantSettingsUrl}
              className="typography-button-1000 underline-offset-4 hover:underline"
            >
              company settings
            </a>
            .
          </p>
        </div>
      )}
    </div>
  )
}

export default ChatPage
