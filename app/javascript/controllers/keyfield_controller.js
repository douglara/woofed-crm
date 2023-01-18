import { Controller } from "stimulus"

export default class extends Controller {
  connect(){
    this.update()
  }

  update(){
    this.element.value = this.element.value.replace(/[^\w\s]/gi, '').replace(/\s/g, '')
  }
}