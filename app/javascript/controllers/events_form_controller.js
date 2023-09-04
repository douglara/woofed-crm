import { Controller } from "stimulus"
import lucide from "lucide/dist/umd/lucide"

export default class extends Controller {
  static targets = ['kindNone', 'kindNote', 'kindActivity']

  connect() {
    lucide.createIcons();
  }

  selectNote() {
    this.hiddenAll()
    this.kindNoteTarget.hidden = false
  }

  selectActivity() {
    this.hiddenAll()
    this.kindActivityTarget.hidden = false
  }

  hiddenAll() {
    this.kindNoneTarget.hidden = true
    this.kindNoteTarget.hidden = true
    this.kindActivityTarget.hidden = true
  }
}