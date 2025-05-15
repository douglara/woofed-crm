import { Controller } from "stimulus";
import debounce from "debounce";

export default class extends Controller {
  static targets = ["modelId", "modelName", "dropdown", "searchForms"];

  connect() {
    this.observeModelNameChanges();
    this.setDropdownId();
  }

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
    this.toggleSubmitButtonVisibility();
  }

  toggleSubmitButtonVisibility() {
    const submitButton = document.querySelector(
      this.element.dataset.submitButtonSelector
    );
    if (submitButton) {
      if (this.modelIdTarget.value) {
        submitButton.classList.remove("hidden");
      } else {
        submitButton.classList.add("hidden");
      }
    }
  }
  observeModelNameChanges() {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (
          mutation.type === "childList" ||
          mutation.type === "characterData"
        ) {
          this.handleModelNameChange();
        }
      });
    });

    observer.observe(this.modelNameTarget, {
      childList: true,
      characterData: true,
      subtree: true,
    });
  }

  setDropdownId() {
    const dropdownSearchId = `dropdownSearch-${Math.random()
      .toString(36)
      .substr(2, 8)}`;

    let dropdownSearchElement = this.dropdownTarget.nextElementSibling;

    this.dropdownTarget.setAttribute("data-dropdown-toggle", dropdownSearchId);
    dropdownSearchElement.id = dropdownSearchId;
  }

  handleModelNameChange() {
    this.toggleSubmitButtonVisibility();
  }
}
