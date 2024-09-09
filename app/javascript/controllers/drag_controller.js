import { Controller } from "stimulus";
import Sortable from "sortablejs";
import Rails from "@rails/ujs";
export default class extends Controller {
  connect() {
    this.sort();
  }

  sort() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      group: "pipeline",
      onAdd: this.end.bind(this),
      onSort: this.end.bind(this),
    });
  }

  async end(event) {
    event.from.classList.add("pointer-events-none");
    event.to.classList.add("pointer-events-none");
    const id = event.item.dataset.id;
    const accountId = event.item.dataset.accountId;
    const to_id = event.to.dataset.id;
    let data = new FormData();
    data.append("deal[position]", event.newIndex + 1);
    data.append("deal[stage_id]", to_id);
    Rails.ajax({
      url: this.data
        .get("url")
        .replace(":deal_id", id)
        .replace(":account_id", accountId),
      type: "PATCH",
      data: data,
    });
  }
}
