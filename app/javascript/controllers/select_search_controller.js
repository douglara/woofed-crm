import { Controller } from "stimulus";
import debounce from "debounce";

export default class extends Controller {
  static targets = ["modelId", "modelName", "dropdown", "searchForms"];

  initialize() {
    this.submit = debounce(this.submit.bind(this), 300);
  }

  submit() {
    this.searchFormsTarget.requestSubmit();
  }

  select(event) {
    this.dropdownTarget.click();
    this.modelIdTarget.value = event.currentTarget.attributes.value.value;
    this.modelNameTarget.innerText =
      event.currentTarget.attributes["model-name"].value;
  }
}
