import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "select", 'formFields' ]

  connect() {
    $(this.selectTarget).on('select2:select', function () {
      let event = new Event('change', { bubbles: true }) // fire a native event
      this.dispatchEvent(event);
    });
  }

  changed() {
    this.formFieldsTarget.hidden = false
  }
}