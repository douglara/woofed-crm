import type { ChatMessage } from '@/types/woofed_ai'
import { AgentMessage, UserMessage } from './MessageItem'
import ChatBlankState from './ChatBlankState'

const Messages = ({ messages }: { messages: ChatMessage[] }) => {
  if (messages.length === 0) {
    return <ChatBlankState />
  }

  return (
    <div className="flex flex-col gap-8">
      {messages.map((message, index) => {
        const key = `${message.role}-${message.created_at}-${index}`
        return message.role === 'agent' ? (
          <AgentMessage key={key} message={message} />
        ) : (
          <UserMessage key={key} message={message} />
        )
      })}
    </div>
  )
}

export default Messages
