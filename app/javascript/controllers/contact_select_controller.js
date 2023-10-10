import { Controller } from "stimulus"
import debounce from "debounce"

export default class extends Controller {
  static targets = ["contactId", "contactName", "dropdown", "searchForms"]

  initialize() {
    this.submit = debounce(this.submit.bind(this), 300) 
  }

  submit() {
    this.searchFormsTarget.requestSubmit();
  }

  select(event) {
    this.dropdownTarget.click();
    this.contactIdTarget.value = event.currentTarget.attributes.value.value;
    this.contactNameTarget.innerText = event.currentTarget.attributes['contact-name'].value;
  }
}