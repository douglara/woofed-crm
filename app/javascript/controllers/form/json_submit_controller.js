import { Controller } from "@hotwired/stimulus"
import { patch, post, put, destroy } from "@rails/request.js"

const METHODS = { patch, post, put, delete: destroy }

export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "patch" }
  }

  submit() {
    const data = this.#formDataToNestedObject()
    const request = METHODS[this.methodValue]

    request(this.urlValue, {
      body: JSON.stringify(data),
      contentType: "application/json",
    })
  }

  #formDataToNestedObject() {
    const formData = new FormData(this.element)
    const data = {}

    formData.forEach((value, key) => {
      const keys = key.replace(/]/g, "").split("[")
      let current = data

      keys.forEach((k, index) => {
        if (index === keys.length - 1) {
          current[k] = value
        } else {
          current[k] = current[k] || {}
          current = current[k]
        }
      })
    })

    return data
  }
}
