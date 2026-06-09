import { useCallback } from 'react'

import type { RunResponse } from '@/types/woofed_ai'

// Ported from agent-ui (src/hooks/useAIResponseStream.tsx). The agent streams a
// concatenated sequence of JSON objects (no SSE framing), so we accumulate a
// buffer and extract every complete top-level object as it arrives.

function isLegacyFormat(data: Record<string, unknown>): boolean {
  return (
    typeof data === 'object' &&
    data !== null &&
    'event' in data &&
    !('data' in data) &&
    typeof data.event === 'string'
  )
}

interface NewFormatData {
  event: string
  data: string | Record<string, unknown>
}

function convertNewFormatToLegacy(newFormatData: NewFormatData): RunResponse {
  const { event, data } = newFormatData
  let parsedData: Record<string, unknown>
  if (typeof data === 'string') {
    try {
      parsedData = JSON.parse(data)
    } catch {
      parsedData = {}
    }
  } else {
    parsedData = data
  }
  return { event, ...parsedData } as unknown as RunResponse
}

// Extracts complete JSON objects from the buffer incrementally, leaving any
// partial trailing object in place for the next chunk.
function parseBuffer(
  buffer: string,
  onChunk: (chunk: RunResponse) => void
): string {
  let jsonStartIndex = buffer.indexOf('{')

  while (jsonStartIndex !== -1 && jsonStartIndex < buffer.length) {
    let braceCount = 0
    let inString = false
    let escapeNext = false
    let jsonEndIndex = -1

    for (let i = jsonStartIndex; i < buffer.length; i++) {
      const char = buffer[i]
      if (inString) {
        if (escapeNext) {
          escapeNext = false
        } else if (char === '\\') {
          escapeNext = true
        } else if (char === '"') {
          inString = false
        }
      } else if (char === '"') {
        inString = true
      } else if (char === '{') {
        braceCount++
      } else if (char === '}') {
        braceCount--
        if (braceCount === 0) {
          jsonEndIndex = i
          break
        }
      }
    }

    if (jsonEndIndex !== -1) {
      const jsonString = buffer.slice(jsonStartIndex, jsonEndIndex + 1)
      try {
        const parsed = JSON.parse(jsonString)
        if (isLegacyFormat(parsed)) {
          onChunk(parsed as RunResponse)
        } else {
          onChunk(convertNewFormatToLegacy(parsed))
        }
      } catch {
        jsonStartIndex = buffer.indexOf('{', jsonStartIndex + 1)
        continue
      }
      buffer = buffer.slice(jsonEndIndex + 1).trim()
      jsonStartIndex = buffer.indexOf('{')
    } else {
      break
    }
  }

  return buffer
}

export interface StreamOptions {
  apiUrl: string
  headers?: Record<string, string>
  requestBody: Record<string, unknown>
  onChunk: (chunk: RunResponse) => void
  onError: (error: Error) => void
  onComplete: () => void
}

export default function useAIResponseStream() {
  const streamResponse = useCallback(
    async (options: StreamOptions): Promise<void> => {
      const { apiUrl, headers = {}, requestBody, onChunk, onError, onComplete } =
        options
      let buffer = ''

      try {
        const response = await fetch(apiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', ...headers },
          body: JSON.stringify(requestBody)
        })

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}))
          throw errorData
        }
        if (!response.body) {
          throw new Error('No response body')
        }

        const reader = response.body.getReader()
        const decoder = new TextDecoder()

        const processStream = async (): Promise<void> => {
          const { done, value } = await reader.read()
          if (done) {
            buffer = parseBuffer(buffer, onChunk)
            onComplete()
            return
          }
          buffer += decoder.decode(value, { stream: true })
          buffer = parseBuffer(buffer, onChunk)
          await processStream()
        }
        await processStream()
      } catch (error) {
        if (typeof error === 'object' && error !== null && 'detail' in error) {
          onError(new Error(String((error as { detail: unknown }).detail)))
        } else {
          onError(new Error(String(error)))
        }
      }
    },
    []
  )

  return { streamResponse }
}
