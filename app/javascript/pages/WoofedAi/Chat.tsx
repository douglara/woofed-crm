import { useMemo } from 'react'
import { Head, router } from '@inertiajs/react'

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

  const basePath = `/accounts/${current_account.id}/woofed_ai`
  const messagesUrl = `${basePath}/messages`
  const sessionsUrl = `${basePath}/sessions`

  return (
    <div className="flex h-full flex-col bg-light-palette-p4">
      <Head title="Woofed AI" />
      <ChatHeader
        model={agent_available ? model : null}
        onNewConversation={() => router.post(sessionsUrl)}
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
          <ChatArea apiUrl={messagesUrl} />
        </ChatProvider>
      ) : (
        <div className="flex flex-1 flex-col items-center justify-center gap-2 px-8 text-center">
          <p className="text-body font-bold text-gray-1100">
            Woofed AI is not available yet
          </p>
          <p className="max-w-md text-subtext font-medium color-fg-soft">
            Enable the AI assistant and set a model and API key in the company
            settings, then make sure the Woofed AI service is running.
          </p>
        </div>
      )}
    </div>
  )
}

export default ChatPage
