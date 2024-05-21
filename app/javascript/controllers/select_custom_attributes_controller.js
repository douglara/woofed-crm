import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["select"];

  connect() {
    this.showSelectOptions();
    this.selectTarget.addEventListener("change", () => {
      this.showSelectOptions();
    });
  }

  showSelectOptions() {
    let optionsSelect = document.getElementById("options-select-custom");
    if (this.selectTarget.value == "select_custom") {
      optionsSelect.style.display = "block";
    } else {
      optionsSelect.style.display = "none";
    }
  }
}
