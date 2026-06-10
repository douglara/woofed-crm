import useAIChatStreamHandler from '@/hooks/woofed_ai/useAIChatStreamHandler'
import { useChat } from './ChatContext'
import MessageArea from './MessageArea'
import ChatBlankState from './ChatBlankState'
import ChatInput from './ChatInput'

// The conversation surface: messages (or the empty state with one-tap
// suggestions) plus the composer. `apiUrl` receives messages; the composer's
// context alert starts a new session via `newSessionUrl`.
const ChatArea = ({
  apiUrl,
  newSessionUrl
}: {
  apiUrl: string
  newSessionUrl: string
}) => {
  const { messages } = useChat()
  const { handleStreamResponse } = useAIChatStreamHandler(apiUrl)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      {messages.length === 0 ? (
        <ChatBlankState onPick={handleStreamResponse} />
      ) : (
        <MessageArea />
      )}
      <ChatInput apiUrl={apiUrl} newSessionUrl={newSessionUrl} />
    </div>
  )
}

export default ChatArea
