import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["input"];
  connect() {
    if (this.inputTarget.value.trim() !== "") {
      this.element.setAttribute("aria-expanded", "true");
    }
  }
  toggle() {
    var expanded = this.element.ariaExpanded === "true";
    this.element.setAttribute("aria-expanded", !expanded);
    if (!expanded) {
      this.inputTarget.focus();
    }
  }
}
