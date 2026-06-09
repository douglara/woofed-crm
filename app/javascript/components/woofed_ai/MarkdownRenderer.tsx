import { type FC } from 'react'
import ReactMarkdown, { type Components } from 'react-markdown'
import rehypeRaw from 'rehype-raw'
import rehypeSanitize from 'rehype-sanitize'
import remarkGfm from 'remark-gfm'

import { cn } from '@/lib/utils'

interface MarkdownRendererProps {
  children: string
  className?: string
}

// Renders agent markdown using the project's Tailwind typography (`prose`)
// tokens. Plain anchors/images replace agent-ui's next/image + next/link.
const components: Components = {
  a: ({ children, ...props }) => (
    <a
      {...props}
      target="_blank"
      rel="noopener noreferrer"
      className="text-primary underline"
    >
      {children}
    </a>
  ),
  img: ({ ...props }) => (
    <img {...props} className="rounded-md" alt={props.alt ?? ''} />
  )
}

const MarkdownRenderer: FC<MarkdownRendererProps> = ({
  children,
  className
}) => (
  <ReactMarkdown
    className={cn(
      'prose prose-sm max-w-none break-words text-foreground prose-pre:bg-muted prose-pre:text-foreground',
      className
    )}
    remarkPlugins={[remarkGfm]}
    rehypePlugins={[rehypeRaw, rehypeSanitize]}
    components={components}
  >
    {children}
  </ReactMarkdown>
)

export default MarkdownRenderer
