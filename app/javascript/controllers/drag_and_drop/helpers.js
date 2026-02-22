export default class DropParamsBuilder {
  constructor(event) {
    this.event = event;
    this.topElement = event.item.previousElementSibling || null;
    this.bottomElement = event.item.nextElementSibling || null;
  }
  buildDropParams() {
    if (this.isMovedBetweenScopes) {
      return this.#paramsForNewScope();
    } else {
      return this.#paramsInCurrentScope();
    }
  }
  get isMovedBetweenScopes() {
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

  #paramsForNewScope() {
    if (this.bottomElement) {
      return {
        element_reference_id: this.bottomElementId,
        element_reference_direction: "bottom",
      };
    }
    if (this.topElement) {
      return {
        element_reference_id: this.topElementId,
        element_reference_direction: "top",
      };
    }

    return { element_reference_id: this.selfElementId };
  }
  #paramsInCurrentScope() {
    if (this.quantityElementsPassed === 0)
      return { element_reference_id: this.selfElementId };
    return this.movementDirection === "up"
      ? { element_reference_id: this.bottomElementId, element_reference_direction: "bottom" }
      : { element_reference_id: this.topElementId, element_reference_direction: "top" };
  }
}
