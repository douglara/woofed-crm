import { memo } from 'react'
import { Sparkles, User } from 'lucide-react'

import type { ChatMessage } from '@/types/woofed_ai'
import { useChat } from './ChatContext'
import MarkdownRenderer from './MarkdownRenderer'
import AgentThinkingLoader from './AgentThinkingLoader'
import ToolCalls from './ToolCalls'

const Avatar = ({ children }: { children: React.ReactNode }) => (
  <div className="flex size-7 shrink-0 items-center justify-center rounded-full bg-muted text-muted-foreground">
    {children}
  </div>
)

const AgentMessage = ({ message }: { message: ChatMessage }) => {
  const { streamingErrorMessage } = useChat()

  let content
  if (message.streamingError) {
    content = (
      <p className="text-destructive">
        Oops! Something went wrong while streaming.{' '}
        {streamingErrorMessage ||
          'Please try refreshing the page or try again later.'}
      </p>
    )
  } else if (message.content) {
    content = <MarkdownRenderer>{message.content}</MarkdownRenderer>
  } else {
    content = <AgentThinkingLoader />
  }

  return (
    <div className="flex flex-col gap-3">
      {message.tool_calls && message.tool_calls.length > 0 && (
        <ToolCalls toolCalls={message.tool_calls} />
      )}
      <div className="flex items-start gap-3">
        <Avatar>
          <Sparkles className="size-4" />
        </Avatar>
        <div className="flex w-full flex-col gap-4 pt-0.5">{content}</div>
      </div>
    </div>
  )
}

const UserMessage = memo(({ message }: { message: ChatMessage }) => (
  <div className="flex items-start gap-3">
    <Avatar>
      <User className="size-4" />
    </Avatar>
    <div className="whitespace-pre-wrap pt-1 text-sm text-foreground">
      {message.content}
    </div>
  </div>
))
UserMessage.displayName = 'UserMessage'

export { AgentMessage, UserMessage }
