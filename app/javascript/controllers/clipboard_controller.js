import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["source", "defaultMessage", "successMessage"];

  copy(event) {
    event.preventDefault();
    navigator.clipboard.writeText(this.sourceTarget.value).then(() => {
      this.showSuccess();
      setTimeout(() => {
        this.resetToDefault();
      }, 2000);
    });
  }
  showSuccess() {
    this.defaultMessageTarget.classList.add("hidden");
    this.successMessageTarget.classList.remove("hidden");
  }
  resetToDefault() {
    this.defaultMessageTarget.classList.remove("hidden");
    this.successMessageTarget.classList.add("hidden");
  }
}
