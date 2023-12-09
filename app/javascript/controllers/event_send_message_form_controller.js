import { Controller } from "stimulus"

export default class extends Controller {
    static targets = ["scheduledAtForm", "radioButtonSendNowFalse", "radioButtonSendNowTrue", 'checkBoxAutoDone', "dateFieldScheduletAt"]
    connect() {
        this.scheduledAtFormTarget.classList.add("hidden");
        this.checkBoxAutoDoneTarget.checked = true
    }

    toggleRadioButton(event) {
        this.resetCheckRadioDiv() 
        event.currentTarget.ariaChecked = 'true'
        var doneInput = event.currentTarget.querySelector('input[type="radio"]');
        var done = doneInput.value === 'true';
        this.radioButtonSendNowTrueTarget.checked = done;
        this.radioButtonSendNowFalseTarget.checked = !done;
        if (done) {
            // this.scheduledAtFormTarget.style.display = 'none';
            this.scheduledAtFormTarget.classList.add("hidden");
            this.checkBoxAutoDoneTarget.checked = true
            this.dateFieldScheduletAtTarget.value = ''
            
        } else {
            // this.scheduledAtFormTarget.style.display = '';
            this.scheduledAtFormTarget.classList.remove("hidden");
            this.checkBoxAutoDoneTarget.checked = false
        }

    }
    resetCheckRadioDiv() {
        this.element.querySelectorAll('.radio-button-div').forEach((x) => {
            x.setAttribute('aria-checked', 'false');
        });
    }

}