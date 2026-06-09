import { Sparkles } from 'lucide-react'

// Shown when the current session has no messages yet.
const ChatBlankState = () => (
  <div className="flex h-full flex-col items-center justify-center gap-3 text-center">
    <div className="flex size-12 items-center justify-center rounded-full bg-muted text-muted-foreground">
      <Sparkles className="size-6" />
    </div>
    <div className="space-y-1">
      <p className="text-lg font-semibold text-foreground">Woofed AI</p>
      <p className="text-sm text-muted-foreground">
        Ask anything about your CRM — contacts, deals, pipelines and more.
      </p>
    </div>
  </div>
)

export default ChatBlankState
