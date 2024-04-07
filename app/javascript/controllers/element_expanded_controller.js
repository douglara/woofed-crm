import { Controller } from "stimulus";
import Rails from "@rails/ujs";

export default class extends Controller {
  static targets = ["sidebar"];
  toggle() {
    var element = document.getElementById("element-expand");
    var expanded = element.ariaExpanded === "true";
    element.ariaExpanded = !expanded;

    if (this.hasSidebarTarget) {
      const currentUrl = window.location.href;
      const url = new URL(currentUrl);
      url.searchParams.set("sidebar_expanded", !expanded);
      console.log(url);
      this.updateSidebarExpanded(!expanded);
    }
  }
  async updateSidebarExpanded(expanded) {
    const currentUrl = window.location.href;
    const url = new URL(currentUrl);
    url.searchParams.set("sidebar_expanded", expanded);
    Rails.ajax({
      url: url,
      type: "GET",
    });
  }
}
