import { Controller } from "stimulus"
import lucide from "lucide/dist/umd/lucide"
import { animate } from "motion"

export default class extends Controller {
  static targets = ['kindNone', 'kindNote', 'kindActivity', 'forms']

  connect() {
    lucide.createIcons();
  }

  selectActivity(e) {
    const elementToInactive = this.formsTarget.querySelector("div[data-events-form-target]:not([hidden])")
    const elementToActive = this.kindActivityTarget
    this.changeForm(elementToActive, elementToInactive)

    const btnToActive = e.currentTarget
    this.changeBtn(btnToActive)
  }

  selectNote(e) {
    const elementToInactive = this.formsTarget.querySelector("div[data-events-form-target]:not([hidden])")
    const elementToActive = this.kindNoteTarget
    this.changeForm(elementToActive, elementToInactive)

    const btnToActive = e.currentTarget
    this.changeBtn(btnToActive)
  }

  selectNone() {
    const elementToInactive = this.formsTarget.querySelector("div[data-events-form-target]:not([hidden])")
    const elementToActive = this.kindNoneTarget
    this.changeForm(elementToActive, elementToInactive)
  }

  changeBtn(btnToActive) {
    try {
      const btnActive = this.element.querySelector(".btn-active")
      btnActive.classList.remove('btn-active')
    }
    catch { }
    btnToActive.classList.add('btn-active')
  }

  changeForm(elementToActive, elementToInactive) {
    try {
      elementToInactive.classList.remove('events-form-active')
      elementToInactive.hidden = true
      animate(
        elementToInactive,
        { x: [0, -20], filter: [ "blur(10px)", "blur(0px)"], opacity: [1, 0]},
        { duration: 0.3 }
      )  
    } catch { }
    try {
      elementToActive.classList.add('events-form-active')
      elementToActive.hidden = false
      animate(
        elementToActive,
        { x: [-20, 0], filter: [ "blur(10px)", "blur(0px)"], opacity: [0, 1]},
        { duration: 0.3 }
      )
    } catch { }
  }
}