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

// Only boot Inertia on actual Inertia pages. The `internal` layout loads this
// entrypoint on every page — including the legacy Turbo/Hotwire pages — but
// initializing Inertia there would attach its global history/popstate listeners
// alongside Turbo Drive. The two then fight over navigation: after leaving an
// Inertia page through Turbo, a later back/forward makes Inertia re-request the
// current (non-Inertia) URL, get HTML back, and pop up the error modal. Guarding
// on the mount element keeps Inertia confined to its own pages.
if (document.getElementById('inertia-app')) {
  // Once Inertia has booted on its page, Inertia and Turbo Drive both hold
  // history/popstate listeners. Force any top-level Turbo Drive visit (e.g. a
  // sidebar link to a legacy page) to do a full browser navigation: that tears
  // Inertia down cleanly so its popstate listener can't later fire against a
  // Turbo-rendered page and pop up the error modal. Frame navigations
  // (`data-turbo-frame` modal/drawer links) don't emit `turbo:before-visit`, so
  // they keep loading into their frames as before.
  document.addEventListener('turbo:before-visit', ((event: CustomEvent<{ url: string }>) => {
    event.preventDefault()
    window.location.href = event.detail.url
  }) as EventListener)

  void createInertiaApp({
  // Mount on a dedicated id (matching `config.root_dom_id` in
  // config/initializers/inertia_rails.rb) so the React app never collides with
  // the `internal` layout's outer `<div id="app">` shell.
  id: 'inertia-app',

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
    console.error('Inertia failed to start', error)
  })
}
