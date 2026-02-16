import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";
import { patch } from "@rails/request.js";

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
    const { closest_deal_id, closest_deal_direction = null } =
      new DropParamsBuilder(event).buildDropParams();

    const body = new FormData();
    body.append("deal[stage_id]", toStageId);
    body.append("deal[closest_deal_id]", closest_deal_id);
    if (closest_deal_direction != null) {
      body.append("deal[closest_deal_direction]", closest_deal_direction);
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

class DropParamsBuilder {
  constructor(event) {
    this.event = event;
    this.topElement = event.item.previousElementSibling || null;
    this.bottomElement = event.item.nextElementSibling || null;
  }
  buildDropParams() {
    if (this.isMovedBetweenStages) {
      return this.#paramsForNewStage();
    } else {
      return this.#paramsInCurrentStage();
    }
  }
  get isMovedBetweenStages() {
    return this.event.from !== this.event.to;
  }
  get movementDirection() {
    const { oldIndex: startIndex, newIndex: endIndex } = this.event;
    return endIndex > startIndex ? "down" : "up";
  }
  get topElementId() {
    return this.topElement.dataset.id;
  }
  get bottomElementId() {
    return this.bottomElement.dataset.id;
  }
  get selfElementId() {
    return this.event.item.dataset.id;
  }
  get quantityElementsPassed() {
    return Math.abs(this.event.oldIndex - this.event.newIndex);
  }

  #paramsForNewStage() {
    if (this.bottomElement) {
      return {
        closest_deal_id: this.bottomElementId,
        closest_deal_direction: "bottom",
      };
    }
    if (this.topElement) {
      return {
        closest_deal_id: this.topElementId,
        closest_deal_direction: "top",
      };
    }

    return { closest_deal_id: this.selfElementId };
  }
  #paramsInCurrentStage() {
    if (this.quantityElementsPassed === 0)
      return { closest_deal_id: this.selfElementId };
    return this.movementDirection === "up"
      ? { closest_deal_id: this.bottomElementId }
      : { closest_deal_id: this.topElementId };
  }
}
