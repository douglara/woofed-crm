import { useEffect, useRef } from 'react'

import { useChat } from './ChatContext'
import Messages from './Messages'

// Scrollable message list that keeps pinned to the bottom as content streams in.
const MessageArea = () => {
  const { messages } = useChat()
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="mx-auto w-full max-w-3xl px-4 py-6">
        <Messages messages={messages} />
        <div ref={bottomRef} />
      </div>
    </div>
  )
}

export default MessageArea
