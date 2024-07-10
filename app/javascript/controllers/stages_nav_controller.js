import { Controller } from "stimulus";

export default class extends Controller {
  static outlets = ["gray-element", "green-element"];

  mouseOver(event) {
    this.toggleStyles(event, "add");
  }

  mouseOut(event) {
    this.toggleStyles(event, "remove");
  }

  toggleStyles(event, action) {
    const color = event.target.getAttribute("data-color");
    const stageElementId = event.target.getAttribute("data-name-stage-id");
    const arrowElementId = event.target.getAttribute("data-arrow-stage-id");
    const linkElementId = event.target.getAttribute("data-link-stage-id");

    if (color === "green" || color === "gray") {
      const colorClass =
        color === "green" ? "auxiliary-palette-green-down" : "gray-200";

      if (stageElementId) {
        this.updateClass(
          `[data-arrow-stage-id="${stageElementId}"]`,
          `!border-l-${colorClass}`,
          action
        );
      }

      if (arrowElementId) {
        if (color === "green") {
          event.target.classList[action]("!text-auxiliary-palette-green");
        }

        const stageName = document.querySelector(
          `[data-name-stage-id="${arrowElementId}"]`
        );
        if (stageName) {
          stageName.parentNode.classList[action](`!bg-${colorClass}`);
          if (color === "green") {
            stageName.classList[action]("!text-auxiliary-palette-green");
          }
        }
      }

      if (linkElementId) {
        this.updateClass(
          `[data-arrow-stage-id="${linkElementId}"]`,
          `!border-l-${colorClass}`,
          action
        );
      }
    }
  }

  updateClass(selector, className, action) {
    const element = document.querySelector(selector);
    if (element) {
      element.classList[action](className);
    }
  }
}
