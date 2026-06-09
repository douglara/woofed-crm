import { useEffect, useRef } from 'react'

import { useChat } from './ChatContext'
import Messages from './Messages'

// Scrollable conversation, pinned to the bottom as new content streams in.
const MessageArea = () => {
  const { messages } = useChat()
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const el = scrollRef.current
    if (el) requestAnimationFrame(() => { el.scrollTop = el.scrollHeight })
  }, [messages])

  return (
    <div ref={scrollRef} className="flex-1 overflow-y-auto px-8 pb-2 pt-[26px]">
      <div className="mx-auto w-full max-w-[740px]">
        <Messages messages={messages} />
      </div>
    </div>
  )
}

export default MessageArea
