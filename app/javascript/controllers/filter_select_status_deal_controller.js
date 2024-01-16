import { Controller } from "stimulus";
import { Dropdown } from "flowbite";

export default class extends Controller {
  static targets = ["status", "form", "links", "button"];
  connect() {
    this.setAllLinksAriaSelectedFalse();
    this.checkParamsUrl();
  }
  select(event) {
    event.preventDefault();
    this.toggleLinkSelected(event);
    const filterValue = event.currentTarget.attributes.value.value;
    filterValue === ""
      ? (this.buttonTarget.ariaSelected = "false")
      : (this.buttonTarget.ariaSelected = "true");
    this.updateUrl(filterValue);
    this.submit(filterValue);
    this.dropdownHide()
  }
  updateUrl(filterValue) {
    const newUrl = `?filter_status_deal=${filterValue}`;
    window.history.pushState({}, "", newUrl);
  }
  submit(filterValue) {
    this.statusTarget.value = filterValue;
    this.formTarget.requestSubmit();
  }
  toggleLinkSelected(event) {
    this.setAllLinksAriaSelectedFalse();
    event.currentTarget.ariaSelected = "true";
  }
  setAllLinksAriaSelectedFalse() {
    var links = this.linksTarget.querySelectorAll("li a");
    links.forEach((link) => (link.ariaSelected = "false"));
  }
  dropdownHide() {
    const dropdwon_element = document.getElementById("dropdownSort");
    const dropdown = new Dropdown(
      dropdwon_element,
      this.buttonTarget
    );
    dropdown.hide();
  }
  checkParamsUrl() {
    var currentUrl = new URL(window.location.href);
    var params = new URLSearchParams(currentUrl.search);
    if (
      params.get("filter_status_deal") &&
      params.get("filter_status_deal") != "open"
    ) {
      this.buttonTarget.ariaSelected = "true";
    }
    var links = this.linksTarget.querySelectorAll("li a");
    links.forEach(function (link) {
      if (link.attributes.value.value === params.get("filter_status_deal")) {
        link.ariaSelected = "true";
      }
    });
  }
}
