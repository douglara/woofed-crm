/* turbo_form_submit_redirect_controller.js */
import { Controller } from "stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:submit-end", (event) => {
      this.next(event)
    })
  }

  next(event) {
    if (event.detail.success) {
      Turbo.visit(event.detail.fetchResponse.response.url)
    }
  }
}