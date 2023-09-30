import { Controller } from "stimulus"

export default class extends Controller {
  toggle() {
    var expanded = (this.element.ariaExpanded === 'true');
    this.element.ariaExpanded = !expanded;    
  }
}