/**
 * AgentPluginBuilderShell – wrapper for all Agent Plugin Builder Inertia pages.
 *
 * Renders children inside the full-height modal body and provides:
 *  - A "close" button (top-right X) that navigates back to the Hotwire
 *    settings page via a full page load (window.location.href), completely
 *    exiting the Inertia overlay and returning the user to the CRM.
 *  - A persistent header bar with the CRM branding.
 */
import { Bot, X } from 'lucide-react'

interface Props {
  settingsUrl: string
  children: React.ReactNode
}

export default function AgentPluginBuilderShell({ settingsUrl, children }: Props) {
  const handleClose = () => {
    window.location.href = settingsUrl
  }

  return (
    <div className="flex flex-col h-full overflow-hidden bg-light-palette-p4">
      {/* Top bar */}
      <div className="flex items-center justify-between px-5 h-12 border-b-2 border-light-palette-p3 bg-light-palette-p5 flex-shrink-0">
        <div className="flex items-center gap-2">
          <div className="w-6 h-6 rounded-md bg-brand-palette-03 flex items-center justify-center">
            <Bot className="w-3.5 h-3.5 text-white" />
          </div>
          <span className="typography-text-m-lh150 text-dark-gray-palette-p1">Agent Plugin Builder</span>
          <span className="typography-micro-m-lh150 text-brand-palette-03 px-2 py-0.5 bg-brand-palette-07 border border-brand-palette-06 rounded-full">
            Beta · IA
          </span>
        </div>

        <button
          onClick={handleClose}
          aria-label="Close"
          className="button-default-blank-secondary-icon-only-sm"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Page content */}
      <div className="flex-1 overflow-hidden">
        {children}
      </div>
    </div>
  )
}
