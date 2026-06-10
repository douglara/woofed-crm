import { useCallback } from 'react'

import { useChat } from '@/components/woofed_ai/ChatContext'
import { getJsonMarkdown } from '@/lib/woofed_ai'
import { RunEvent, type RunResponse, type ToolCall } from '@/types/woofed_ai'
import useAIResponseStream from './useAIResponseStream'

const csrfToken = (): string =>
  document
    .querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
    ?.content ?? ''

// Ported from agent-ui (src/hooks/useAIStreamHandler.tsx), stripped of
// teams/nuqs/zustand. It optimistically appends the user message + an empty
// agent message, then folds streamed chunks into that agent message. Requests
// go to the Rails proxy (apiUrl) which forwards to the agent.
const useAIChatStreamHandler = (apiUrl: string) => {
  const {
    setMessages,
    addMessage,
    sessionId,
    setIsStreaming,
    setStreamingErrorMessage,
    focusChatInput
  } = useChat()
  const { streamResponse } = useAIResponseStream()

  const updateMessagesWithErrorState = useCallback(() => {
    setMessages((prev) => {
      const newMessages = [...prev]
      const lastMessage = newMessages[newMessages.length - 1]
      if (lastMessage && lastMessage.role === 'agent') {
        lastMessage.streamingError = true
      }
      return newMessages
    })
  }, [setMessages])

  const processToolCall = useCallback(
    (
      toolCall: ToolCall,
      prevToolCalls: ToolCall[] = [],
      status?: ToolCall['status']
    ) => {
      const incoming = status ? { ...toolCall, status } : toolCall
      const toolCallId =
        incoming.tool_call_id || `${incoming.tool_name}-${incoming.created_at}`
      const existingIndex = prevToolCalls.findIndex(
        (tc) =>
          (tc.tool_call_id && tc.tool_call_id === incoming.tool_call_id) ||
          (!tc.tool_call_id &&
            incoming.tool_name &&
            incoming.created_at &&
            `${tc.tool_name}-${tc.created_at}` === toolCallId)
      )
      if (existingIndex >= 0) {
        const updated = [...prevToolCalls]
        updated[existingIndex] = { ...updated[existingIndex], ...incoming }
        return updated
      }
      return [...prevToolCalls, incoming]
    },
    []
  )

  const processChunkToolCalls = useCallback(
    (chunk: RunResponse, existing: ToolCall[] = [], status?: ToolCall['status']) => {
      let updated = [...existing]
      if (chunk.tool) {
        updated = processToolCall(chunk.tool, updated, status)
      }
      if (chunk.tools && chunk.tools.length > 0) {
        for (const toolCall of chunk.tools) {
          updated = processToolCall(toolCall, updated, status)
        }
      }
      return updated
    },
    [processToolCall]
  )

  const handleStreamResponse = useCallback(
    async (input: string) => {
      setIsStreaming(true)
      setStreamingErrorMessage('')

      // Drop a previous failed user/agent pair so a retry stays clean.
      setMessages((prev) => {
        if (prev.length >= 2) {
          const last = prev[prev.length - 1]
          const secondLast = prev[prev.length - 2]
          if (
            last.role === 'agent' &&
            last.streamingError &&
            secondLast.role === 'user'
          ) {
            return prev.slice(0, -2)
          }
        }
        return prev
      })

      addMessage({
        role: 'user',
        content: input,
        created_at: Math.floor(Date.now() / 1000)
      })
      addMessage({
        role: 'agent',
        content: '',
        tool_calls: [],
        streamingError: false,
        created_at: Math.floor(Date.now() / 1000) + 1
      })

      let lastContent = ''
      try {
        await streamResponse({
          apiUrl,
          headers: { 'X-CSRF-Token': csrfToken() },
          requestBody: { message: input, session_id: sessionId },
          onChunk: (chunk: RunResponse) => {
            if (
              chunk.event === RunEvent.ToolCallStarted ||
              chunk.event === RunEvent.ToolCallCompleted
            ) {
              setMessages((prev) => {
                const newMessages = [...prev]
                const last = newMessages[newMessages.length - 1]
                if (last && last.role === 'agent') {
                  const status =
                    chunk.event === RunEvent.ToolCallCompleted
                      ? 'done'
                      : 'running'
                  last.tool_calls = processChunkToolCalls(
                    chunk,
                    last.tool_calls,
                    status
                  )
                }
                return newMessages
              })
            } else if (chunk.event === RunEvent.RunContent) {
              setMessages((prev) => {
                const newMessages = [...prev]
                const last = newMessages[newMessages.length - 1]
                if (last && last.role === 'agent') {
                  if (typeof chunk.content === 'string') {
                    const uniqueContent = chunk.content.replace(lastContent, '')
                    last.content += uniqueContent
                    lastContent = chunk.content
                    last.tool_calls = processChunkToolCalls(
                      chunk,
                      last.tool_calls
                    )
                    if (chunk.extra_data?.reasoning_steps) {
                      last.extra_data = {
                        ...last.extra_data,
                        reasoning_steps: chunk.extra_data.reasoning_steps
                      }
                    }
                    if (chunk.extra_data?.references) {
                      last.extra_data = {
                        ...last.extra_data,
                        references: chunk.extra_data.references
                      }
                    }
                    last.created_at = chunk.created_at ?? last.created_at
                  } else if (chunk.content != null) {
                    const jsonBlock = getJsonMarkdown(chunk.content)
                    last.content += jsonBlock
                    lastContent = jsonBlock
                  }
                }
                return newMessages
              })
            } else if (chunk.event === RunEvent.ReasoningStep) {
              setMessages((prev) => {
                const newMessages = [...prev]
                const last = newMessages[newMessages.length - 1]
                if (last && last.role === 'agent') {
                  const existingSteps =
                    last.extra_data?.reasoning_steps ?? []
                  const incomingSteps = chunk.extra_data?.reasoning_steps ?? []
                  last.extra_data = {
                    ...last.extra_data,
                    reasoning_steps: [...existingSteps, ...incomingSteps]
                  }
                }
                return newMessages
              })
            } else if (chunk.event === RunEvent.RunError) {
              updateMessagesWithErrorState()
              setStreamingErrorMessage(
                (chunk.content as string) || 'Error during run'
              )
            } else if (chunk.event === RunEvent.RunCompleted) {
              setMessages((prev) =>
                prev.map((message, index) => {
                  if (index === prev.length - 1 && message.role === 'agent') {
                    const updatedContent =
                      typeof chunk.content === 'string'
                        ? chunk.content
                        : getJsonMarkdown(chunk.content ?? {})
                    return {
                      ...message,
                      content: updatedContent,
                      tool_calls: processChunkToolCalls(
                        chunk,
                        // Any tool still mid-flight is finished once the run
                        // completes.
                        message.tool_calls?.map((tc) => ({
                          ...tc,
                          status: 'done' as const
                        })),
                        'done'
                      ),
                      created_at: chunk.created_at ?? message.created_at,
                      extra_data: {
                        reasoning_steps:
                          chunk.extra_data?.reasoning_steps ??
                          message.extra_data?.reasoning_steps,
                        references:
                          chunk.extra_data?.references ??
                          message.extra_data?.references
                      }
                    }
                  }
                  return message
                })
              )
            }
          },
          onError: (error) => {
            updateMessagesWithErrorState()
            setStreamingErrorMessage(error.message)
          },
          onComplete: () => {}
        })
      } catch (error) {
        updateMessagesWithErrorState()
        setStreamingErrorMessage(
          error instanceof Error ? error.message : String(error)
        )
      } finally {
        focusChatInput()
        setIsStreaming(false)
      }
    },
    [
      apiUrl,
      sessionId,
      addMessage,
      setMessages,
      setIsStreaming,
      setStreamingErrorMessage,
      focusChatInput,
      streamResponse,
      processChunkToolCalls,
      updateMessagesWithErrorState
    ]
  )

  return { handleStreamResponse }
}

export default useAIChatStreamHandler
