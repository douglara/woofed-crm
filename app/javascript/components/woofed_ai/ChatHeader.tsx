import { Plus } from 'lucide-react'

import WoofedIcon from './WoofedIcon'

interface ChatHeaderProps {
  model: string | null
  onNewConversation: () => void
}

// Top bar of the chat surface: assistant identity + active model on the left,
// "new session" action on the right.
const ChatHeader = ({ model, onNewConversation }: ChatHeaderProps) => (
  <div className="flex h-[72px] shrink-0 items-center justify-between border-b-[1.5px] color-border-default color-bg-surface-default px-8">
    <div className="flex items-center gap-3">
      <WoofedIcon size={38} />
      <div>
        <span className="font-extrabold text-gray-1100 text-body">Woofed AI</span>
        {model && (
          <div className="flex items-center gap-1.5">
            <span className="size-[7px] rounded-full color-bg-feedback-success-harder" />
            <span className="typography-micro-s color-fg-soft">{model}</span>
          </div>
        )}
      </div>
    </div>
    <button
      type="button"
      onClick={onNewConversation}
      className="button-default-fill-secondary-md"
    >
      <Plus />
      New session
    </button>
  </div>
)

export default ChatHeader
