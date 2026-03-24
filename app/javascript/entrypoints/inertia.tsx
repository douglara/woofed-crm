import { createInertiaApp, router, type ResolvedComponent } from '@inertiajs/react'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'

// Inject JWT into Inertia requests and native fetch() when inside an iframe
// (e.g. Chatwoot Dashboard App where 3rd-party cookies are blocked)
if (window.self !== window.top) {
  const jwtKey = () => Object.keys(localStorage).find((k) => k.startsWith('embed_jwt_'))

  router.on('before', (event) => {
    const key = jwtKey()
    const jwt = key ? localStorage.getItem(key) : null
    if (jwt) {
      event.detail.visit.headers = event.detail.visit.headers ?? {}
      event.detail.visit.headers['Authorization'] = `Bearer ${jwt}`
    }
  })

  const _originalFetch = window.fetch.bind(window)
  window.fetch = function (input: RequestInfo | URL, init: RequestInit = {}) {
    const key = jwtKey()
    const jwt = key ? localStorage.getItem(key) : null
    if (jwt) {
      init.headers = { ...(init.headers as Record<string, string> ?? {}), Authorization: `Bearer ${jwt}` }
    }
    return _originalFetch(input, init)
  }
}

void createInertiaApp({
  // Set default page title
  // see https://inertia-rails.dev/guide/title-and-meta
  //
  // title: title => title ? `${title} - App` : 'App',

  // Disable progress bar
  //
  // see https://inertia-rails.dev/guide/progress-indicators
  // progress: false,

  resolve: (name) => {
    const pages = import.meta.glob<{default: ResolvedComponent}>('../pages/**/*.tsx', {
      eager: true,
    })
    const page = pages[`../pages/${name}.tsx`]
    if (!page) {
      console.error(`Missing Inertia page component: '${name}.tsx'`)
    }

    // To use a default layout, import the Layout component
    // and use the following line.
    // see https://inertia-rails.dev/guide/pages#default-layouts
    //
    // page.default.layout ||= (page: ReactNode) => (<Layout>{page}</Layout>)

    return page
  },

  setup({ el, App, props }) {
    createRoot(el).render(
      <StrictMode>
        <App {...props} />
      </StrictMode>
    )
  },

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
    },
    future: {
      useScriptElementForInitialPage: true,
      useDataInertiaHeadAttribute: true,
      useDialogForErrorModal: true,
      preserveEqualProps: true,
    },
  },
}).catch((error) => {
  // This ensures this entrypoint is only loaded on Inertia pages
  // by checking for the presence of the root element (#app by default).
  // Feel free to remove this `catch` if you don't need it.
  if (document.getElementById("app")) {
    throw error
  } else {
    console.error(
      "Missing root element.\n\n" +
      "If you see this error, it probably means you loaded Inertia.js on non-Inertia pages.\n" +
      'Consider moving <%= vite_typescript_tag "inertia.tsx" %> to the Inertia-specific layout instead.',
    )
  }
})
