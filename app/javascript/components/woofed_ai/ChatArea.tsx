import MessageArea from './MessageArea'
import ChatInput from './ChatInput'

// Chat surface: the scrolling message list plus a sticky composer.
const ChatArea = ({ apiUrl }: { apiUrl: string }) => (
  <div className="flex h-full flex-col">
    <MessageArea />
    <div className="sticky bottom-0 border-t color-border-default bg-background px-4 py-4">
      <ChatInput apiUrl={apiUrl} />
    </div>
  </div>
)

export default ChatArea
