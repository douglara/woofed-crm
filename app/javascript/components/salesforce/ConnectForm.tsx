import { useForm } from '@inertiajs/react'

import type { SalesforceConnection } from '@/types/salesforce'

interface ConnectFormProps {
  connection: SalesforceConnection | null
  submitUrl: string
}

/**
 * The credentials the customer copied out of their External Client App. The
 * setup steps that produce them live in SetupGuide, above this card.
 */
const ConnectForm = ({ connection, submitUrl }: ConnectFormProps) => {
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
          Paste the Consumer Key and Consumer Secret from step 8.
        </p>
      </header>

      <form
        className="flex flex-col gap-5 px-6 py-5"
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
    </section>
  )
}

export default ConnectForm
