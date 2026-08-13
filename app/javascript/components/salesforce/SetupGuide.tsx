import { useState } from 'react'
import { AlertTriangle, ChevronDown, ChevronUp } from 'lucide-react'

import CopyableValue from '@/components/salesforce/CopyableValue'

interface SetupGuideProps {
  callbackUrl: string
  scopes: string
  // Open while there is no connection; collapsed afterwards, since the callback
  // URL is still needed whenever the app has to be rebuilt in Salesforce.
  defaultOpen: boolean
}

const REQUIREMENTS = [
  'A Salesforce edition with API access: Enterprise, Unlimited, Performance or Developer. Professional and Essentials only have it with the API add-on, which Salesforce charges for — without it no integration can read your data, this one included.',
  'A Salesforce user with the “API Enabled” permission, and permission to create apps (“Customize Application”).',
  'That user must be able to see the records you want to import: Woofed reads exactly what they can read, and nothing more.'
]

const STEPS = [
  {
    title: 'Open Setup in Salesforce',
    body: 'Click the gear icon at the top right and choose Setup.'
  },
  {
    title: 'Create the app',
    body: 'In the quick find box type “App Manager”, open it, and click New External Client App. Name it “Woofed CRM” and fill in a contact email.'
  },
  {
    title: 'Enable OAuth',
    body: 'Open the API (Enable OAuth Settings) section and tick “Enable OAuth”.'
  },
  {
    title: 'Paste the callback URL',
    body: 'Copy the value below into the Callback URL field. It has to match character for character — a mistyped URL is the most common reason a connection fails, and Salesforce reports it only as “redirect_uri_mismatch”.'
  },
  {
    title: 'Select the scopes',
    body: 'Move exactly these two into Selected OAuth Scopes: “Manage user data via APIs (api)” and “Perform requests at any time (refresh_token, offline_access)”. The first lets Woofed read your records; the second keeps the connection alive without asking you to log in again.'
  },
  {
    title: 'Turn on PKCE and the refresh token',
    body: 'Tick “Require Proof Key for Code Exchange (PKCE)” and “Issue a refresh token”. Under Refresh Token Policy choose “Refresh token is valid until revoked”, otherwise the sync stops working when the token expires.'
  },
  {
    title: 'Save and wait',
    body: 'Save the app. Salesforce takes up to ten minutes to propagate a new app — connecting before that fails with an invalid client error.'
  },
  {
    title: 'Copy the credentials',
    body: 'Open the app, go to Settings → OAuth Settings → Consumer Key and Secret, and copy both values. Paste them in the form below, pick production or sandbox, and connect.'
  }
]

/**
 * Woofed never provisions anything on the Salesforce side: the customer creates
 * the External Client App themselves, in their own org. This screen is therefore
 * the setup documentation, and carries the two values that must match exactly.
 */
const SetupGuide = ({ callbackUrl, scopes, defaultOpen }: SetupGuideProps) => {
  const [open, setOpen] = useState(defaultOpen)

  return (
  <section className="rounded-md border color-border-default color-bg-surface-default">
    <header className="flex flex-wrap items-start justify-between gap-4 px-6 py-5">
      <div className="flex flex-col gap-1">
        <h2 className="typography-sub-title-900 color-fg-hard">
          Before you connect
        </h2>
        <p className="typography-body-900 color-fg-soft">
          The app lives in your Salesforce org. Woofed only consumes the
          credentials it gives you, and never changes anything in Salesforce.
        </p>
      </div>

      <button
        type="button"
        onClick={() => setOpen(!open)}
        className="button-default-outline-secondary-sm"
      >
        {open ? <ChevronUp /> : <ChevronDown />}
        {open ? 'Hide steps' : 'Show steps'}
      </button>
    </header>

    {open && (
    <div className="flex flex-col gap-6 border-t color-border-default px-6 py-5">
      <div className="flex flex-col gap-3 rounded-md border color-border-feedback-danger-default color-bg-feedback-danger-default px-4 py-3">
        <div className="flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 stroke-1 shrink-0" />
          <span className="typography-sub-title-800 color-fg-feedback-danger">
            API access is required
          </span>
        </div>
        <ul className="flex list-disc flex-col gap-2 pl-5">
          {REQUIREMENTS.map((requirement) => (
            <li key={requirement} className="typography-body-900 color-fg-feedback-danger">
              {requirement}
            </li>
          ))}
        </ul>
      </div>

      <ol className="flex flex-col gap-4">
        {STEPS.map((step, index) => (
          <li key={step.title} className="flex items-start gap-3">
            <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full color-bg-fill-hard typography-button-800 color-fg-highlight">
              {index + 1}
            </span>
            <div className="flex flex-col gap-1">
              <span className="typography-sub-title-800 color-fg-hard">
                {step.title}
              </span>
              <span className="typography-body-900 color-fg-soft">{step.body}</span>
            </div>
          </li>
        ))}
      </ol>

      <CopyableValue label="Callback URL (step 4)" value={callbackUrl} />
      <CopyableValue label="Scopes (step 5)" value={scopes} />

      <p className="typography-body-900 color-fg-extra-soft">
        After connecting, map the Salesforce objects onto Woofed models below.
        Nothing is imported until you map an object, enable it and run the first
        sync.
      </p>
    </div>
    )}
  </section>
  )
}

export default SetupGuide
