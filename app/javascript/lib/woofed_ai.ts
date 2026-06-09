import type { ChatMessage, SessionRun, ToolCall } from '@/types/woofed_ai'

// Wraps a non-string agent payload in a fenced JSON markdown block so the
// MarkdownRenderer can display it. Ported from agent-ui's getJsonMarkdown.
export const getJsonMarkdown = (content: object = {}): string => {
  try {
    return `\`\`\`json\n${JSON.stringify(content, null, 2)}\n\`\`\``
  } catch {
    return `\`\`\`\n${String(content)}\n\`\`\``
  }
}

const normalizeContent = (content: SessionRun['content']): string => {
  if (typeof content === 'string') return content
  if (content == null) return ''
  return getJsonMarkdown(content)
}

// Flattens the agno session runs into the flat user/agent ChatMessage list the
// UI renders. Ported from agent-ui's useSessionLoader mapping.
export const mapRunsToMessages = (runs: SessionRun[]): ChatMessage[] =>
  runs.flatMap((run) => {
    const messages: ChatMessage[] = []

    messages.push({
      role: 'user',
      content: run.run_input ?? '',
      created_at: run.created_at
    })

    const toolCalls: ToolCall[] = [
      ...(run.tools ?? []),
      ...(run.extra_data?.reasoning_messages ?? []).reduce<ToolCall[]>(
        (acc, msg) => {
          if (msg.role === 'tool') {
            acc.push({
              role: msg.role,
              content: msg.content,
              tool_call_id: msg.tool_call_id ?? '',
              tool_name: msg.tool_name ?? '',
              tool_args: msg.tool_args ?? {},
              tool_call_error: msg.tool_call_error ?? false,
              metrics: msg.metrics ?? { time: 0 },
              created_at: msg.created_at ?? Math.floor(Date.now() / 1000)
            })
          }
          return acc
        },
        []
      )
    ]

    messages.push({
      role: 'agent',
      content: normalizeContent(run.content),
      tool_calls: toolCalls.length > 0 ? toolCalls : undefined,
      extra_data: run.extra_data,
      created_at: run.created_at
    })

    return messages
  })
