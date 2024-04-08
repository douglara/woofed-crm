import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["sidebar"];
  connect() {
    if (this.hasSidebarTarget && localStorage.getItem("sidebar_expanded")) {
      this.setAriaExpanded(localStorage.getItem("sidebar_expanded"));
    }
  }
  toggle() {
    var element = document.getElementById("element-expand");
    var expanded = element.ariaExpanded === "true";
    element.ariaExpanded = !expanded;

    if (this.hasSidebarTarget) {
      this.setLocalStorageSidebarExpanded(!expanded);
    }
  }
  setLocalStorageSidebarExpanded(value) {
    localStorage.setItem("sidebar_expanded", value);
    this.setAriaExpanded(value);
  }
  setAriaExpanded(value) {
    this.element.setAttribute("aria-expanded", value);
  }
}
