import { Wrench } from 'lucide-react'

import type { ToolCall } from '@/types/woofed_ai'

// Renders the agent's tool calls as compact chips above the message.
const ToolCalls = ({ toolCalls }: { toolCalls: ToolCall[] }) => (
  <div className="flex items-start gap-2">
    <div className="flex size-6 shrink-0 items-center justify-center rounded-md bg-muted text-muted-foreground">
      <Wrench className="size-3.5" />
    </div>
    <div className="flex flex-wrap gap-2">
      {toolCalls.map((toolCall, index) => (
        <span
          key={
            toolCall.tool_call_id ||
            `${toolCall.tool_name}-${toolCall.created_at}-${index}`
          }
          className="rounded-full bg-muted px-2 py-1 text-xs font-medium uppercase text-muted-foreground"
        >
          {toolCall.tool_name}
        </span>
      ))}
    </div>
  </div>
)

export default ToolCalls
