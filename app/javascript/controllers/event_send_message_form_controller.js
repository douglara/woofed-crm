import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["scheduledAtForm", "radioButtonDoneFalse", "radioButtonDoneTrue", 'checkBoxAutoDone', "dateFieldScheduletAt"]

    toggleRadioButton(event) {
        this.resetCheckRadioDiv() 
        event.currentTarget.ariaChecked = 'true'
        var doneInput = event.currentTarget.querySelector('input[type="radio"]');
        var done = doneInput.value === 'true';
        this.radioButtonDoneTrueTarget.checked = done;
        this.radioButtonDoneFalseTarget.checked = !done;
        if (done) {
            this.scheduledAtFormTarget.style.display = 'none';
            this.checkBoxAutoDoneTarget.checked = false
            this.dateFieldScheduletAtTarget.value = ''
            
        } else {
            this.scheduledAtFormTarget.style.display = '';
        }

    }
    resetCheckRadioDiv() {
        this.element.querySelectorAll('.radio-button-div').forEach((x) => {
            x.setAttribute('aria-checked', 'false');
        });
    }

}