// Types for the Woofed AI chat, ported and trimmed from the agno agent-ui
// (ai-agent/agent-ui/src/types/os.ts) to the subset the CRM chat needs.

export interface ToolCall {
  role: 'user' | 'tool' | 'system' | 'assistant'
  content: string | null
  tool_call_id: string
  tool_name: string
  tool_args: Record<string, string>
  tool_call_error: boolean
  metrics: { time: number }
  created_at: number
  // UI-only: tracks whether the tool is still executing or has finished, so the
  // tool-call trace can show a spinner vs a check.
  status?: 'running' | 'done'
}

export interface ReasoningSteps {
  title: string
  action?: string
  result: string
  reasoning: string
  confidence?: number
  next_action?: string
}

export interface ReasoningMessage {
  role: 'user' | 'tool' | 'system' | 'assistant'
  content: string | null
  tool_call_id?: string
  tool_name?: string
  tool_args?: Record<string, string>
  tool_call_error?: boolean
  metrics?: { time: number }
  created_at?: number
}

export interface Reference {
  content: string
  meta_data: { chunk: number; chunk_size: number }
  name: string
}

export interface ReferenceData {
  query: string
  references: Reference[]
  time?: number
}

export interface AgentExtraData {
  reasoning_steps?: ReasoningSteps[]
  reasoning_messages?: ReasoningMessage[]
  references?: ReferenceData[]
}

export enum RunEvent {
  RunStarted = 'RunStarted',
  RunContent = 'RunContent',
  RunCompleted = 'RunCompleted',
  RunError = 'RunError',
  ToolCallStarted = 'ToolCallStarted',
  ToolCallCompleted = 'ToolCallCompleted',
  ReasoningStarted = 'ReasoningStarted',
  ReasoningStep = 'ReasoningStep',
  ReasoningCompleted = 'ReasoningCompleted'
}

export interface RunResponse {
  content?: string | object
  content_type?: string
  event: RunEvent
  messages?: unknown[]
  run_id?: string
  agent_id?: string
  session_id?: string
  tool?: ToolCall
  tools?: ToolCall[]
  created_at: number
  extra_data?: AgentExtraData
}

export interface ChatMessage {
  role: 'user' | 'agent' | 'system' | 'tool'
  content: string
  streamingError?: boolean
  created_at: number
  tool_calls?: ToolCall[]
  extra_data?: AgentExtraData
}

// A single run as returned by the agno session-runs endpoint, consumed when
// seeding the chat with prior history (see mapRunsToMessages).
export interface SessionRun {
  run_input?: string
  content?: string | object
  tools?: ToolCall[]
  extra_data?: AgentExtraData
  created_at: number
}
