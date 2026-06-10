import { memo } from 'react'

import type { ChatMessage } from '@/types/woofed_ai'
import { useChat } from './ChatContext'
import WoofedIcon from './WoofedIcon'
import MarkdownRenderer from './MarkdownRenderer'
import AgentThinkingLoader from './AgentThinkingLoader'
import ToolCallTrace from './ToolCallTrace'

const AgentMessage = ({
  message,
  isLast
}: {
  message: ChatMessage
  isLast: boolean
}) => {
  const { streamingErrorMessage, isStreaming } = useChat()
  const showCaret = isLast && isStreaming && message.content.length > 0
  const isThinking = !message.content && !message.streamingError

  return (
    <div className="mb-[22px] flex items-start gap-3">
      <WoofedIcon />
      <div className="min-w-0 flex-1 pt-0.5">
        <div className="mb-1.5 flex items-center gap-2">
          <span className="typography-micro-b text-gray-1100">Woofed AI</span>
          {isThinking && (
            <span className="typography-micro-s text-gray-700">
              is thinking…
            </span>
          )}
        </div>

        {message.tool_calls && message.tool_calls.length > 0 && (
          <ToolCallTrace
            toolCalls={message.tool_calls}
            running={isLast && isStreaming}
          />
        )}

        {message.streamingError ? (
          <p className="text-subtext color-fg-feedback-danger">
            Oops! Something went wrong while streaming.{' '}
            {streamingErrorMessage ||
              'Please try refreshing the page or try again later.'}
          </p>
        ) : isThinking ? (
          <AgentThinkingLoader />
        ) : (
          <div className="text-subtext font-medium leading-relaxed color-fg-default">
            <MarkdownRenderer>{message.content}</MarkdownRenderer>
            {showCaret && (
              <span
                className="ml-0.5 inline-block h-[15px] w-[7px] rounded-[1px] align-text-bottom color-bg-fill-highlight"
                style={{ animation: 'wfCaret 0.9s infinite step-end' }}
              />
            )}
          </div>
        )}
      </div>
    </div>
  )
}

const UserMessage = memo(({ message }: { message: ChatMessage }) => (
  <div className="mb-[22px] flex justify-end">
    <div className="max-w-[74%] whitespace-pre-wrap rounded-[14px_14px_4px_14px] color-bg-fill-highlight px-[15px] py-2.5 text-subtext font-semibold leading-normal color-fg-inverse shadow-sm">
      {message.content}
    </div>
  </div>
))
UserMessage.displayName = 'UserMessage'

export { AgentMessage, UserMessage }
