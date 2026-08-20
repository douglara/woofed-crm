import { useState } from 'react'
import { Check, Copy } from 'lucide-react'

interface CopyableValueProps {
  label: string
  value: string
}

/**
 * The callback URL and the scope list have to be pasted into Salesforce by hand.
 * A mistyped callback is the single most likely onboarding failure, so both are
 * shown verbatim with a copy button rather than described in prose.
 */
const CopyableValue = ({ label, value }: CopyableValueProps) => {
  const [copied, setCopied] = useState(false)

  const copy = async () => {
    await navigator.clipboard.writeText(value)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="grid gap-2">
      <span className="typography-label-900 color-fg-soft">{label}</span>
      <div className="flex items-center gap-2">
        <code className="flex-1 overflow-x-auto rounded-md border color-border-default color-bg-surface-hard px-4 py-2 typography-body-900 color-fg-default">
          {value}
        </code>
        <button
          type="button"
          onClick={copy}
          className="button-default-outline-secondary-sm whitespace-nowrap"
        >
          {copied ? <Check /> : <Copy />}
          {copied ? 'Copied' : 'Copy'}
        </button>
      </div>
    </div>
  )
}

export default CopyableValue
