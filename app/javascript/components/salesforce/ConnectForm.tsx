import { useForm } from '@inertiajs/react'

import CopyableValue from '@/components/salesforce/CopyableValue'
import type { SalesforceConnection } from '@/types/salesforce'

interface ConnectFormProps {
  connection: SalesforceConnection | null
  callbackUrl: string
  scopes: string
  submitUrl: string
}

const SETUP_STEPS = [
  'In Salesforce, go to Setup → App Manager → New External Client App.',
  'Enable OAuth and paste the callback URL below.',
  'Select the scopes below, and enable “Issue a refresh token” and PKCE.',
  'Save, wait a few minutes for Salesforce to propagate the app, then copy its Consumer Key and Consumer Secret.'
]

/**
 * Woofed never provisions anything on the Salesforce side: the customer creates
 * the External Client App themselves. This card is therefore also the setup
 * documentation, and carries the two values that have to match exactly.
 */
const ConnectForm = ({
  connection,
  callbackUrl,
  scopes,
  submitUrl
}: ConnectFormProps) => {
  const { data, setData, post, processing, errors } = useForm({
    apps_salesforce: {
      name: connection?.name || 'Salesforce',
      environment: connection?.environment || 'production',
      client_id: '',
      client_secret: ''
    }
  })

  const setField = (field: string, value: string) =>
    setData('apps_salesforce', { ...data.apps_salesforce, [field]: value })

  const errorMessages = Object.values(errors)
  const inputClasses =
    'rounded-md border color-border-default color-bg-surface-hard px-4 py-2 typography-body-900 color-fg-default focus:outline-none focus:color-border-harder'

  return (
    <section className="rounded-md border color-border-default color-bg-surface-default">
      <header className="border-b color-border-default px-6 py-5">
        <h2 className="typography-sub-title-900 color-fg-hard">
          {connection ? 'Reconnect org' : 'Connect an org'}
        </h2>
        <p className="typography-body-900 color-fg-soft">
          You create the app inside Salesforce; Woofed only consumes the
          credentials it gives you.
        </p>
      </header>

      <div className="flex flex-col gap-5 px-6 py-5">
        <ol className="flex flex-col gap-3">
          {SETUP_STEPS.map((step, index) => (
            <li key={step} className="flex items-start gap-3">
              <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full color-bg-fill-hard typography-button-800 color-fg-highlight">
                {index + 1}
              </span>
              <span className="typography-body-900 color-fg-soft">{step}</span>
            </li>
          ))}
        </ol>

        <CopyableValue label="Callback URL" value={callbackUrl} />
        <CopyableValue label="Scopes" value={scopes} />

        <div className="h-px w-full color-bg-fill-default" />

        <form
          className="flex flex-col gap-5"
          onSubmit={(event) => {
            event.preventDefault()
            post(submitUrl)
          }}
        >
          {errorMessages.length > 0 && (
            <p className="rounded-md border color-border-feedback-danger-default color-bg-feedback-danger-default px-4 py-2 typography-body-900 color-fg-feedback-danger">
              {errorMessages.join(', ')}
            </p>
          )}

          <div className="grid gap-2">
            <label
              htmlFor="salesforce-environment"
              className="typography-label-900 color-fg-soft"
            >
              Environment
            </label>
            <select
              id="salesforce-environment"
              className={inputClasses}
              value={data.apps_salesforce.environment}
              onChange={(event) => setField('environment', event.target.value)}
            >
              <option value="production">Production</option>
              <option value="sandbox">Sandbox</option>
            </select>
          </div>

          <div className="grid gap-2">
            <label
              htmlFor="salesforce-client-id"
              className="typography-label-900 color-fg-soft"
            >
              Consumer key
            </label>
            <input
              id="salesforce-client-id"
              className={inputClasses}
              value={data.apps_salesforce.client_id}
              onChange={(event) => setField('client_id', event.target.value)}
            />
          </div>

          <div className="grid gap-2">
            <label
              htmlFor="salesforce-client-secret"
              className="typography-label-900 color-fg-soft"
            >
              Consumer secret
            </label>
            <input
              id="salesforce-client-secret"
              type="password"
              className={inputClasses}
              value={data.apps_salesforce.client_secret}
              onChange={(event) => setField('client_secret', event.target.value)}
            />
          </div>

          <button
            type="submit"
            disabled={processing}
            className="button-default-fill-primary-md self-end disabled:opacity-50"
          >
            {connection ? 'Reconnect to Salesforce' : 'Connect to Salesforce'}
          </button>
        </form>
      </div>
    </section>
  )
}

export default ConnectForm
