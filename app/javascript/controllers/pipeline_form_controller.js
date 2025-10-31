import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["statusText"]

  updateStatus(event) {
    const checked = event.target.checked
    if (this.hasStatusTextTarget) {
      this.statusTextTarget.textContent = checked ? 'Ativo' : 'Desativado'
    }
  }
}
