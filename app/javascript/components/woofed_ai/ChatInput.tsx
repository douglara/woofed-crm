import { useState } from 'react'
import { SendHorizontal } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import useAIChatStreamHandler from '@/hooks/woofed_ai/useAIChatStreamHandler'
import { useChat } from './ChatContext'

// Message composer. Enter sends, Shift+Enter inserts a newline.
const ChatInput = ({ apiUrl }: { apiUrl: string }) => {
  const { chatInputRef, isStreaming } = useChat()
  const { handleStreamResponse } = useAIChatStreamHandler(apiUrl)
  const [inputMessage, setInputMessage] = useState('')

  const handleSubmit = async () => {
    if (!inputMessage.trim() || isStreaming) return
    const message = inputMessage
    setInputMessage('')
    await handleStreamResponse(message)
  }

  return (
    <div className="mx-auto flex w-full max-w-3xl items-end gap-2">
      <Textarea
        ref={chatInputRef}
        placeholder="Ask anything"
        value={inputMessage}
        onChange={(e) => setInputMessage(e.target.value)}
        onKeyDown={(e) => {
          if (
            e.key === 'Enter' &&
            !e.nativeEvent.isComposing &&
            !e.shiftKey &&
            !isStreaming
          ) {
            e.preventDefault()
            handleSubmit()
          }
        }}
        className="min-h-11 flex-1 bg-background"
      />
      <Button
        type="button"
        size="icon-lg"
        onClick={handleSubmit}
        disabled={!inputMessage.trim() || isStreaming}
      >
        <SendHorizontal className="size-4" />
      </Button>
    </div>
  )
}

export default ChatInput
