import { Controller } from "stimulus"

export default class extends Controller {
  toggle() {
    var element = document.getElementById("element-expand")
    var expanded = (element.ariaExpanded === 'true');
    element.ariaExpanded = !expanded;    
  }
}