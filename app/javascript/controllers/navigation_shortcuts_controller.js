import { Controller } from "@hotwired/stimulus";
import * as Turbo from "@hotwired/turbo";
import { getMetaJSON } from "../utils/meta";

export default class extends Controller {
  connect() {
    this.accountId = getMetaJSON("user-data").account_id;
  }
  navigateToAdvancedSearch(event) {
    if (event.ctrlKey || event.metaKey) {
      event.preventDefault();
      Turbo.visit(`/accounts/${this.accountId}/advanced_search`, {
        frame: "modal",
      });
    }
  }
}
