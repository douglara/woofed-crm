import { Controller } from "stimulus"
import lucide from "lucide/dist/umd/lucide"
import { animate } from "motion"

export default class extends Controller {
  static targets = ['kindNone', 'kindNote', 'kindActivity', 'forms', 'kindChatwootConnect', 'kindEvolutionApiConnect']

  connect() {
    lucide.createIcons();
  }
  selectElement(e, targetElement) {
    const elementToInactive = this.formsTarget.querySelector("div[data-events-form-target]:not([hidden])")
    const elementToActive = targetElement
    this.changeForm(elementToActive, elementToInactive)

    const btnToActive = e.currentTarget
    this.changeBtn(btnToActive)
  }
  selectActivity(e) {
    this.selectElement(e, this.kindActivityTarget)
  }
  selectEvolutionApiConnect(e) {
    this.selectElement(e, this.kindEvolutionApiConnectTarget)
  }
  selectNote(e) {
    this.selectElement(e, this.kindNoteTarget)
  }

  selectChatwootConnect(e) {
    this.selectElement(e, this.kindChatwootConnectTarget)
  }

  selectNone(e) {
    this.selectElement(e, this.kindNoneTarget)
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
    this.animationBlurAndMove(elementToActive, elementToInactive)
  }

  animationUpDown(elementToActive, elementToInactive) {
    try {
      const elementToInactiveHeight = elementToInactive.offsetHeight
      animate(
        elementToInactive,
        { height:0, y: [0, -elementToInactiveHeight], opacity: [1, 0]},
        { duration: 0.2 }
      ).finished.then(() => {

        elementToInactive.classList.remove('events-form-active')
        elementToInactive.hidden = true
        animate(elementToInactive, { height: "auto", opacity: 1 })

        try {
          elementToActive.classList.add('events-form-active')
          elementToActive.hidden = false
          animate(
            elementToActive,
            { height: [0, "auto" ], y: [-elementToInactiveHeight, 0]},
            { duration: 0.2 }
          )
        } catch { }
      })
    } catch { }
  }

  animationBlur(elementToActive, elementToInactive) {
    try {
      elementToInactive.classList.remove('events-form-active')
      elementToInactive.hidden = true
      animate(
        elementToInactive,
        { filter: [ "blur(10px)", "blur(0px)"], opacity: [1, 0]},
        { duration: 0.3 }
      )
    } catch { }
    try {
      elementToActive.classList.add('events-form-active')
      elementToActive.hidden = false
      animate(
        elementToActive,
        { filter: [ "blur(10px)", "blur(0px)"], opacity: [0, 1]},
        { duration: 0.3 }
      )
    } catch { }

  }

  animationBlurAndMove(elementToActive, elementToInactive) {
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
