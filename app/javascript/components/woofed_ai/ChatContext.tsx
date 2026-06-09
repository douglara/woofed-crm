import {
  createContext,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
  type RefObject
} from 'react'

import type { ChatMessage } from '@/types/woofed_ai'

// Small React context replacing agent-ui's zustand store. It holds just the
// chat state the components and streaming hooks share.
interface ChatContextValue {
  messages: ChatMessage[]
  setMessages: (
    messages: ChatMessage[] | ((prev: ChatMessage[]) => ChatMessage[])
  ) => void
  addMessage: (message: ChatMessage) => void
  isStreaming: boolean
  setIsStreaming: (isStreaming: boolean) => void
  streamingErrorMessage: string
  setStreamingErrorMessage: (message: string) => void
  sessionId: string | null
  chatInputRef: RefObject<HTMLTextAreaElement | null>
  focusChatInput: () => void
}

const ChatContext = createContext<ChatContextValue | null>(null)

interface ChatProviderProps {
  children: ReactNode
  sessionId: string | null
  initialMessages: ChatMessage[]
}

export const ChatProvider = ({
  children,
  sessionId,
  initialMessages
}: ChatProviderProps) => {
  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages)
  const [isStreaming, setIsStreaming] = useState(false)
  const [streamingErrorMessage, setStreamingErrorMessage] = useState('')
  const chatInputRef = useRef<HTMLTextAreaElement | null>(null)

  const value = useMemo<ChatContextValue>(
    () => ({
      messages,
      setMessages,
      addMessage: (message) => setMessages((prev) => [...prev, message]),
      isStreaming,
      setIsStreaming,
      streamingErrorMessage,
      setStreamingErrorMessage,
      sessionId,
      chatInputRef,
      focusChatInput: () => {
        setTimeout(() => {
          requestAnimationFrame(() => chatInputRef.current?.focus())
        }, 0)
      }
    }),
    [messages, isStreaming, streamingErrorMessage, sessionId]
  )

  return <ChatContext.Provider value={value}>{children}</ChatContext.Provider>
}

export const useChat = (): ChatContextValue => {
  const context = useContext(ChatContext)
  if (!context) {
    throw new Error('useChat must be used within a ChatProvider')
  }
  return context
}
