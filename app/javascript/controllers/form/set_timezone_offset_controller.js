import { Controller } from "stimulus";

export default class extends Controller {
  connect() {
    const offset = this.timezoneOffset;

    if (this.isLink(this.element)) {
      const url = new URL(this.element.href);
      url.searchParams.set("timezone_offset", offset);
      this.element.href = url.toString();
    } else if (this.isInput(this.element)) {
      this.element.value = offset;
    }
  }

  isLink(element) {
    return element.tagName === "A";
  }

  isInput(element) {
    return element.tagName === "INPUT";
  }

  get timezoneOffset() {
    return -new Date().getTimezoneOffset() / 60;
  }
}
