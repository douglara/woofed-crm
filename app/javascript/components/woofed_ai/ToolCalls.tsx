import { Wrench } from 'lucide-react'

import type { ToolCall } from '@/types/woofed_ai'

// The agent's tool calls, shown as compact pills above its message.
const ToolCalls = ({ toolCalls }: { toolCalls: ToolCall[] }) => (
  <div className="flex items-start gap-2">
    <span className="flex size-6 shrink-0 items-center justify-center rounded-md color-bg-fill-default color-fg-soft">
      <Wrench className="size-3.5" />
    </span>
    <div className="flex flex-wrap gap-2">
      {toolCalls.map((toolCall, index) => (
        <span
          key={
            toolCall.tool_call_id ||
            `${toolCall.tool_name}-${toolCall.created_at}-${index}`
          }
          className="rounded-full color-bg-fill-default px-2 py-1 typography-micro-s uppercase color-fg-soft"
        >
          {toolCall.tool_name}
        </span>
      ))}
    </div>
  </div>
)

export default ToolCalls
