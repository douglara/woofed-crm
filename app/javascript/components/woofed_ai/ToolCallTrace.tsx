import { useState } from 'react'
import { Wrench, ChevronDown, Check } from 'lucide-react'

import type { ToolCall } from '@/types/woofed_ai'

const isDone = (tool: ToolCall) => tool.status !== 'running'

// First tool argument, rendered as the call's argument (e.g. name("StartupX")).
const firstArg = (tool: ToolCall): string | null => {
  const values = Object.values(tool.tool_args ?? {})
  return values.length > 0 ? String(values[0]) : null
}

const StatusIcon = ({ tool }: { tool: ToolCall }) => {
  if (tool.status === 'running') {
    return (
      <span className="size-[18px] shrink-0 animate-spin rounded-full border-2 border-purple-300 border-t-purple-600" />
    )
  }
  return (
    <span className="flex size-[18px] shrink-0 items-center justify-center rounded-full color-bg-feedback-success-default color-fg-feedback-success animate-in zoom-in-50">
      <Check className="size-3 stroke-[2.5]" />
    </span>
  )
}

const ToolCallRow = ({
  tool,
  isLast
}: {
  tool: ToolCall
  isLast: boolean
}) => {
  const arg = firstArg(tool)
  return (
    <div className="relative flex items-center gap-2.5 py-[5px] animate-in fade-in slide-in-from-bottom-1">
      {!isLast && (
        <span className="absolute bottom-[-5px] left-[8.5px] top-[23px] w-px color-bg-fill-hard bg-gray-300" />
      )}
      <StatusIcon tool={tool} />
      <span
        className={`flex shrink-0 ${tool.status === 'running' ? 'color-fg-highlight' : 'color-fg-soft'}`}
      >
        <Wrench className="size-3.5" />
      </span>
      <span className="min-w-0 flex-1 truncate font-mono text-micro font-semibold">
        <span className="text-purple-700">{tool.tool_name}</span>
        <span className="text-gray-600">(</span>
        {arg != null && (
          <span
            className={isDone(tool) ? 'color-fg-feedback-success' : 'color-fg-soft'}
          >
            &quot;{arg}&quot;
          </span>
        )}
        <span className="text-gray-600">)</span>
      </span>
      {tool.status === 'running' && (
        <span className="shrink-0 text-[11px] font-bold color-fg-highlight">
          running…
        </span>
      )}
    </div>
  )
}

// A collapsible trace of the tools the agent used (or is using) before replying.
const ToolCallTrace = ({
  toolCalls,
  running
}: {
  toolCalls: ToolCall[]
  running: boolean
}) => {
  const [open, setOpen] = useState(true)
  if (toolCalls.length === 0) return null

  const doneCount = toolCalls.filter((t) => t.status === 'done').length
  const allDone = doneCount === toolCalls.length && !running

  return (
    <div className="mb-3 max-w-[440px] overflow-hidden rounded-[9px] border-[1.5px] color-border-default color-bg-fill-default">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="flex w-full select-none items-center gap-2.5 px-3 py-2.5 text-left"
      >
        <span
          className={`flex size-[22px] shrink-0 items-center justify-center rounded-md ${
            allDone
              ? 'color-bg-feedback-success-default color-fg-feedback-success'
              : 'bg-purple-200 color-fg-highlight'
          }`}
        >
          <Wrench className="size-3.5" />
        </span>
        <span className="text-micro font-bold text-gray-1100">
          {running ? 'Using tools' : 'Tools used'}
        </span>
        <span className="rounded-full border-[1.5px] color-border-default color-bg-surface-default px-2 py-px text-[11px] font-bold text-gray-700">
          {running ? `${doneCount}/${toolCalls.length}` : toolCalls.length}
        </span>
        <span className="flex-1" />
        <ChevronDown
          className={`size-3.5 text-gray-700 transition-transform ${open ? '' : '-rotate-90'}`}
        />
      </button>
      {open && (
        <div className="border-t-[1.5px] color-border-default px-3.5 pb-2.5 pt-0.5">
          {toolCalls.map((tool, index) => (
            <ToolCallRow
              key={
                tool.tool_call_id ||
                `${tool.tool_name}-${tool.created_at}-${index}`
              }
              tool={tool}
              isLast={index === toolCalls.length - 1}
            />
          ))}
        </div>
      )}
    </div>
  )
}

export default ToolCallTrace
