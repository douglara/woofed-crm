import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "input", "otherField"];
  static values = {
    freeFormLostReasons: Boolean,
  };

  connect() {
    if (!this.freeFormLostReasonsValue) {
      this.removeOtherOption();
      return;
    }
    this.formName = this.selectTarget.name;
  }

  toggle(event) {
    if (!this.freeFormLostReasonsValue) return;
    const select = event.target;
    const isOther = select.selectedIndex === select.options.length - 1;

    if (isOther) {
      this.showOtherInput();
    } else {
      this.hideOtherInput();
    }
  }

  showOtherInput() {
    this.selectTarget.removeAttribute("name");

    this.otherFieldTarget.classList.remove("hidden");
    this.otherFieldTarget.classList.add("flex");

    this.inputTarget.disabled = false;
    this.inputTarget.name = this.formName;
    this.inputTarget.focus();
  }

  hideOtherInput() {
    this.otherFieldTarget.classList.add("hidden");

    this.selectTarget.name = this.formName;
    this.inputTarget.removeAttribute("name");
    this.inputTarget.disabled = true;
    this.inputTarget.value = "";
  }

  removeOtherOption() {
    const options = this.selectTarget.options;
    if (options.length > 0) {
      this.selectTarget.remove(options.length - 1);
    }
  }
}
