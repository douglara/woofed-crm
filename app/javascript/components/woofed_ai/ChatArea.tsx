import useAIChatStreamHandler from '@/hooks/woofed_ai/useAIChatStreamHandler'
import { useChat } from './ChatContext'
import MessageArea from './MessageArea'
import ChatBlankState from './ChatBlankState'
import ChatInput from './ChatInput'

// The conversation surface: messages (or the empty state with one-tap
// suggestions) plus the composer. Both send to `apiUrl`.
const ChatArea = ({ apiUrl }: { apiUrl: string }) => {
  const { messages } = useChat()
  const { handleStreamResponse } = useAIChatStreamHandler(apiUrl)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      {messages.length === 0 ? (
        <ChatBlankState onPick={handleStreamResponse} />
      ) : (
        <MessageArea />
      )}
      <ChatInput apiUrl={apiUrl} />
    </div>
  )
}

export default ChatArea
