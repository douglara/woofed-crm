export default class DropParamsBuilder {
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
