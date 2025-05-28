import { Controller } from "stimulus";
import Sortable from "sortablejs";
import Rails from "@rails/ujs";
import * as Turbo from "@hotwired/turbo";

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
    const newPosition = new Position(event).getNewPosition();
    const fromStageId = event.from.dataset.id;
    let data = new FormData();
    data.append("deal[position]", newPosition);
    data.append("deal[stage_id]", toStageId);
    Rails.ajax({
      url: this.data
        .get("url")
        .replace(":deal_id", dealId)
        .replace(":account_id", accountId),
      type: "PATCH",
      data: data,
      beforeSend: (xhr) => {
        xhr.setRequestHeader("Accept", "text/vnd.turbo-stream.html");
        return true;
      },
      success: (response) => {
        Turbo.renderStreamMessage(response);
        event.from.classList.remove("pointer-events-none");
        event.to.classList.remove("pointer-events-none");
      },
      error: (response) => {
        Turbo.renderStreamMessage(response);
        const fromList = document.querySelector(`ul[data-id="${fromStageId}"]`);
        if (fromList && event.item) {
          fromList.insertBefore(event.item, fromList.firstChild);
        }

        event.from.classList.remove("pointer-events-none");
        event.to.classList.remove("pointer-events-none");
      },
    });
  }

  disableDrag() {
    this.sortable.option("disabled", true);
  }

  enableDrag() {
    this.sortable.option("disabled", false);
  }
}

class Position {
  constructor(event) {
    this.event = event;
    this.previousElement = event.item.previousElementSibling || null;
    this.nextElement = event.item.nextElementSibling || null;
  }
  getNewPosition() {
    if (this.isMovedBetweenStages) {
      return this.positionForNewStage();
    } else {
      return this.positionInCurrentStage();
    }
  }
  get isMovedBetweenStages() {
    return this.event.from !== this.event.to;
  }
  get movementDirection() {
    const { oldIndex: startIndex, newIndex: endIndex } = this.event;
    return endIndex > startIndex ? "down" : "up";
  }
  get previousElementPosition() {
    return parseInt(this.previousElement.dataset.position, 10);
  }
  get nextElementPosition() {
    return parseInt(this.nextElement.dataset.position, 10);
  }
  get quantityElementsPassed() {
    return Math.abs(this.event.oldIndex - this.event.newIndex);
  }
  get elementCurrentPosition() {
    return parseInt(this.event.item.dataset.position, 10);
  }

  positionForNewStage() {
    if (this.nextElement) {
      return this.nextElementPosition + 1;
    }
    if (this.previousElement) {
      if (this.previousElementPosition === 1) return 1;
      return this.previousElementPosition - 1;
    }

    return null;
  }
  positionInCurrentStage() {
    if (this.quantityElementsPassed === 0) return this.elementCurrentPosition;
    return this.movementDirection === "up"
      ? this.nextElementPosition
      : this.previousElementPosition;
  }
}
