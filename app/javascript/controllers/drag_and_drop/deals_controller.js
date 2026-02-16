import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";
import { patch } from "@rails/request.js";
import DropParamsBuilder from "./helpers";

export default class extends Controller {
  connect() {
    this.sort();
  }

  sort() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      sort: true,
      group: "pipeline",
      onEnd: this.end.bind(this),
      onStart: () => {
        document.body.classList.add("is-dragging");
      },
      forceFallback: true,
    });
  }

  async end(event) {
    event.from.classList.add("pointer-events-none");
    event.to.classList.add("pointer-events-none");
    document.body.classList.remove("is-dragging");
    const dealId = event.item.dataset.id;
    const accountId = event.item.dataset.accountId;
    const toStageId = event.to.dataset.id;
    const fromStageId = event.from.dataset.id;
    const { element_reference_id, element_reference_direction = null } =
      new DropParamsBuilder(event).buildDropParams();

    const body = new FormData();
    body.append("deal[stage_id]", toStageId);
    body.append("deal[element_reference_id]", element_reference_id);
    if (element_reference_direction != null) {
      body.append(
        "deal[element_reference_direction]",
        element_reference_direction,
      );
    }

    const url = this.data
      .get("url")
      .replace(":deal_id", dealId)
      .replace(":account_id", accountId);

    try {
      const response = await patch(url, {
        body,
        responseKind: "turbo-stream",
      });

      if (response.ok) {
        event.from.classList.remove("pointer-events-none");
        event.to.classList.remove("pointer-events-none");
      } else {
        this.errorAction(event, fromStageId);
      }
    } catch (error) {
      this.errorAction(event, fromStageId);
    }
  }

  disableDrag() {
    this.sortable.option("disabled", true);
  }

  enableDrag() {
    this.sortable.option("disabled", false);
  }
  errorAction(event, fromStageId) {
    const fromList = document.querySelector(`ul[data-id="${fromStageId}"]`);
    if (fromList && event.item) {
      fromList.insertBefore(event.item, fromList.firstChild);
    }
    event.from.classList.remove("pointer-events-none");
    event.to.classList.remove("pointer-events-none");
  }
}
