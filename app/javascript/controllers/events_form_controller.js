import { Controller } from "stimulus"
import lucide from "lucide/dist/umd/lucide"
import { animate } from "motion"

export default class extends Controller {
  static targets = ['kindNone', 'kindNote', 'kindActivity']

  connect() {
    lucide.createIcons();
  }

  selectNone() {
    this.hiddenAll()
    this.kindNoneTarget.hidden = false
    this.kindNoneTarget.classList.add('events-form-active')
  }

  selectNote(e) {
    this.hiddenAll()
    this.kindNoteTarget.hidden = false
    this.kindNoteTarget.classList.add('events-form-active')
    e.currentTarget.classList.add('btn-active')
  }

  selectActivity(e) {
    this.hiddenAll()
    this.kindActivityTarget.hidden = false
    this.kindActivityTarget.classList.add('events-form-active')
    e.currentTarget.classList.add('btn-active')
  }

  hiddenAll() {
    this.disableBtn()
    const activeElement = this.element.querySelector(".events-form-active")
    activeElement.hidden = true
    activeElement.classList.remove('events-form-active')

    // animate(
    //   activeElement,
    //   { x: [0, -20], filter: [ "blur(10px)", "blur(0px)"], opacity: [1, 0]},
    //   { duration: 0.3 }
    // )
  }

  disableBtn() {
    try {
      const btnActive = this.element.querySelector(".btn-active")
      btnActive.classList.remove('btn-active')
    }
    catch { }
  }
}