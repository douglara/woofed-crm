import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { embeddingToken: String, accountId: Number }

  connect() {
    const storedJwt = this.#loadStoredJwt()
    this.#listenForChatwootMessage(storedJwt)
    window.parent.postMessage('chatwoot-dashboard-app:fetch-info', '*')
  }

  #loadStoredJwt() {
    return localStorage.getItem(`embed_jwt_${this.embeddingTokenValue}`)
  }

  #saveJwt(jwt) {
    localStorage.setItem(`embed_jwt_${this.embeddingTokenValue}`, jwt)
  }

  #listenForChatwootMessage(existingJwt) {
    const handleMessage = async (event) => {
      if (!this.#isChatwootAppContext(event)) return
      window.removeEventListener('message', handleMessage)

      const jwt = existingJwt || await this.#fetchJwt(event.data)
      if (!jwt) return

      const contact = this.#extractContact(event.data)
      if (!contact) return

      this.#submitContactSearch(jwt, contact)
    }

    window.addEventListener('message', handleMessage)
  }

  #isChatwootAppContext(event) {
    return typeof event.data === 'string' && event.data.includes('appContext')
  }

  async #fetchJwt(eventData) {
    try {
      const resp = await fetch('/apps/chatwoots/embedding_generate_jwt', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content ?? ''
        },
        body: JSON.stringify({ token: this.embeddingTokenValue, event: eventData })
      })
      if (!resp.ok) return null
      const { jwt } = await resp.json()
      this.#saveJwt(jwt)
      return jwt
    } catch {
      return null
    }
  }

  #extractContact(eventData) {
    return JSON.parse(eventData)?.data?.contact ?? null
  }

  #submitContactSearch(jwt, contact) {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = `/accounts/${this.accountIdValue}/contacts/chatwoot_embed/search`
    form.dataset.turbo = 'false'

    this.#addHiddenField(form, 'embed_jwt', jwt)
    this.#addHiddenField(form, 'chatwoot_contact', JSON.stringify(contact))

    document.body.appendChild(form)
    form.submit()
  }

  #addHiddenField(form, name, value) {
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = name
    input.value = value
    form.appendChild(input)
  }
}
