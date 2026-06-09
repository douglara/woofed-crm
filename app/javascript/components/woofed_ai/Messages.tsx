import type { ChatMessage } from '@/types/woofed_ai'
import { AgentMessage, UserMessage } from './MessageItem'

const Messages = ({ messages }: { messages: ChatMessage[] }) => (
  <>
    {messages.map((message, index) => {
      const key = `${message.role}-${message.created_at}-${index}`
      // The last message is the one currently streaming, so AgentMessage shows
      // its blinking caret only there.
      const isLast = index === messages.length - 1
      return message.role === 'agent' ? (
        <AgentMessage key={key} message={message} isLast={isLast} />
      ) : (
        <UserMessage key={key} message={message} />
      )
    })}
  </>
)

export default Messages
