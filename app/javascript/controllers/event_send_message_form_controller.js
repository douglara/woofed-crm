import { Controller } from "stimulus";

export default class extends Controller {
  static targets = [
    "scheduledAtForm",
    "radioButtonSendNowFalse",
    "radioButtonSendNowTrue",
    "checkBoxAutoDone",
    "dateFieldScheduletAt",
  ];
  connect() {
    this.handleScheduledAtFormVisibility()
  }

  toggleRadioButton(event) {
    this.resetAllSendNowWrapper();
    event.currentTarget.ariaChecked = "true";
    var currentSendNowRadioButton = event.currentTarget.querySelector(
      'input[type="radio"]'
    );
    var isSendNowTrue = currentSendNowRadioButton.value === "true";
    this.toggleRadionButtonsChecked(isSendNowTrue)
    this.handleScheduledAtFormVisibility()
    this.handleSendNow(isSendNowTrue);
  }
  handleSendNow(isSendNowTrue) {
    if (isSendNowTrue) {
      this.checkBoxAutoDoneTarget.checked = isSendNowTrue;
      this.dateFieldScheduletAtTarget.value = "";
    }

  }
  toggleRadionButtonsChecked(value) {
    this.radioButtonSendNowTrueTarget.checked = value;
    this.radioButtonSendNowFalseTarget.checked = !value;
  }
  handleScheduledAtFormVisibility() {
    if (this.radioButtonSendNowTrueTarget.checked) {
      this.scheduledAtFormTarget.classList.add("hidden");
      this.checkBoxAutoDoneTarget.checked = 'true';
    } else {
      this.scheduledAtFormTarget.classList.remove("hidden");
    }
  }

  resetAllSendNowWrapper() {
    this.element.querySelectorAll(".send-now-wrapper").forEach((x) => {
      x.setAttribute("aria-checked", "false");
    });
  }
}
