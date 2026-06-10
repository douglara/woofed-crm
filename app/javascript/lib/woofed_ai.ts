import type { ChatMessage, SessionRun, ToolCall } from '@/types/woofed_ai'

// The agent only replays its last `HISTORY_RUNS` runs (num_history_runs in
// ai-agent/main.py); a "run" is one user turn + its reply. Past that, the
// earliest turns drop out of context — so we warn the user as the conversation
// approaches the limit and flag it as critical once it's reached.
export const HISTORY_RUNS = 20
const WARN_RATIO = 0.8

export type ContextLevel = 'off' | 'warn' | 'crit'

export interface ContextStatus {
  level: ContextLevel
  pct: number
  runs: number
}

// A run is materialized by each user turn, so counting user messages gives the
// number of runs the agent must keep in context.
export const computeContext = (messages: ChatMessage[]): ContextStatus => {
  const runs = messages.filter((m) => m.role === 'user').length
  const pct = Math.min(100, Math.round((runs / HISTORY_RUNS) * 100))
  if (runs >= HISTORY_RUNS) return { level: 'crit', pct, runs }
  if (runs >= Math.round(HISTORY_RUNS * WARN_RATIO)) {
    return { level: 'warn', pct, runs }
  }
  return { level: 'off', pct, runs }
}

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
      // Tools from history have already finished running.
      ...(run.tools ?? []).map((tool) => ({ ...tool, status: 'done' as const })),
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
              created_at: msg.created_at ?? Math.floor(Date.now() / 1000),
              status: 'done' as const
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
