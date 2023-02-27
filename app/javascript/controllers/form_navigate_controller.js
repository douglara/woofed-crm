import { Controller } from "stimulus"

export default class extends Controller {
  
  to(e) {
    const { url } = e.target.dataset;
    this.element.action = url;
    this.element.method = "get";
    this.element.requestSubmit()
  }
}