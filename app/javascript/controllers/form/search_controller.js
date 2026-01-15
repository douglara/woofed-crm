import { Controller } from "@hotwired/stimulus";
import debounce from "debounce";

export default class extends Controller {
  static targets = ["form"];

  initialize() {
    this.submit = debounce(this.submit.bind(this), 300);
  }

  submit() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit();
    }
  }
}
