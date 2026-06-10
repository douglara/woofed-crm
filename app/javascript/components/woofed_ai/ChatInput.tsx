import { useState } from 'react'
import { SendHorizontal } from 'lucide-react'
import { router } from '@inertiajs/react'

import useAIChatStreamHandler from '@/hooks/woofed_ai/useAIChatStreamHandler'
import { computeContext } from '@/lib/woofed_ai'
import { useChat } from './ChatContext'
import SessionAlert from './SessionAlert'

interface ChatInputProps {
  apiUrl: string
  newSessionUrl: string
}

// Message composer. Enter sends, Shift+Enter inserts a newline. Auto-grows up
// to a max height. (No attachment button by request.) Shows the context alert
// above the input as the conversation approaches the agent's history window.
const ChatInput = ({ apiUrl, newSessionUrl }: ChatInputProps) => {
  const { chatInputRef, isStreaming, messages } = useChat()
  const { handleStreamResponse } = useAIChatStreamHandler(apiUrl)
  const [value, setValue] = useState('')
  const [dismissed, setDismissed] = useState(false)

  const canSend = value.trim().length > 0 && !isStreaming

  const context = computeContext(messages)
  // Critical alerts can't be dismissed; warnings can (until a new session
  // remounts this component and resets the flag).
  const showAlert =
    context.level === 'crit' || (context.level === 'warn' && !dismissed)

  const submit = () => {
    if (!canSend) return
    const message = value
    setValue('')
    if (chatInputRef.current) chatInputRef.current.style.height = 'auto'
    handleStreamResponse(message)
  }

  return (
    <div className="shrink-0 px-8 pb-[22px]">
      <div className="mx-auto max-w-[740px]">
        {showAlert && context.level !== 'off' && (
          <SessionAlert
            level={context.level}
            pct={context.pct}
            onNewSession={() => router.post(newSessionUrl)}
            onDismiss={() => setDismissed(true)}
          />
        )}
        <div className="flex items-end gap-2.5 rounded-xl border-[1.5px] color-border-default color-bg-surface-default py-2.5 pl-3.5 pr-2.5 shadow-sm">
          <textarea
            ref={chatInputRef}
            rows={1}
            value={value}
            placeholder="Ask anything to Woofed AI…"
            onChange={(e) => {
              setValue(e.target.value)
              const el = e.target
              el.style.height = 'auto'
              el.style.height = `${Math.min(el.scrollHeight, 140)}px`
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.nativeEvent.isComposing && !e.shiftKey) {
                e.preventDefault()
                submit()
              }
            }}
            className="max-h-[140px] flex-1 resize-none border-none bg-transparent py-1.5 text-subtext font-medium leading-normal color-fg-default outline-none placeholder:text-gray-700 focus:border-transparent focus:outline-none focus:ring-0"
          />
          <button
            type="button"
            onClick={submit}
            disabled={!canSend}
            className={`flex size-[38px] shrink-0 items-center justify-center rounded-lg transition-colors ${
              canSend
                ? 'color-bg-fill-highlight color-fg-inverse hover:color-bg-fill-highlight-hover'
                : 'color-bg-fill-default color-fg-soft'
            }`}
          >
            <SendHorizontal className="size-[18px]" />
          </button>
        </div>
        <p className="mt-2.5 text-center typography-micro-m text-gray-600">
          Woofed AI can make mistakes. Review the results before confirming.
        </p>
      </div>
    </div>
  )
}

export default ChatInput
