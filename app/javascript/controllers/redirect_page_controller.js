import { Controller } from "stimulus"

export default class extends Controller {
  static values = { url: String }
  connect() {
    window.location.href = this.urlValue
  }
}
