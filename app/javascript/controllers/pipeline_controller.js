import { Controller } from "stimulus"
import { get, post, put, patch, destroy } from '@rails/request.js'
import Rails from "@rails/ujs"


export default class extends Controller {
  static targets = ["deal"]

  connect() {
    console.log('eai')
  }
  dragStart(event) {
    event.target.style.opacity = "0.4"
    this.dragSrcEl = event.target

    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData("text/html", event.target.innerHTML)
  }

  dragEnter(event) {
    event.target.classList.add('over')

    if (event.preventDefault){
      event.preventDefault()
    }
    return false
  }

  dragOver(event) {
    if (event.preventDefault) {
      event.preventDefault()
    }
    return false
  }

  dragLeave(event) {
    event.target.classList.remove('over')
    this.resetOpacity()
  }

  async drop(event) {
    console.log('soltou')
    event.stopPropagation()

    event.target.classList.remove('over')
    this.resetOpacity()

    var el = event.target
    console.log(el)
    var account_id = el.getAttribute('account_id')
    var deal_id = el.getAttribute('deal_id')
    var stage_id = el.parentElement.getAttribute('id')

    const response = await put(`/accounts/${account_id}/deals/${deal_id}`,
    { body: JSON.stringify({"deal":{"stage_id": stage_id}})  }
    )
    if (response.ok) {
      Turbo.readStreamMessage
    }

  }

  dragEnd() {
    this.resetOpacity()
  }

  resetOpacity() {
    this.dealTargets.forEach((el) => {
      el.style.opacity = "1"
    })
  }

}