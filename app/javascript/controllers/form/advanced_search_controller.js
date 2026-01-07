import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["searchTypeField", "filterButton", "form", "searchInput"];

  selectFilter(event) {
    event.preventDefault();

    const clickedButton = event.currentTarget;

    this.applySelection(clickedButton);
    this.updateSearchType(clickedButton.dataset.value);

    if (this.hasSearchInputTarget) {
      this.searchInputTarget.focus();
    }
  }

  updateSearchType(value) {
    if (this.searchTypeFieldTarget.value === value) return;

    this.searchTypeFieldTarget.value = value;

    if (this.hasFormTarget) {
      this.formTarget.requestSubmit();
    }
  }

  applySelection(button) {
    this.unselectAllFilters();
    this.markAsSelected(button);
  }

  unselectAllFilters() {
    this.filterButtonTargets.forEach((button) => {
      button.setAttribute("aria-selected", "false");
    });
  }

  markAsSelected(button) {
    button.setAttribute("aria-selected", "true");
  }
}
