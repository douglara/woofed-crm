import { Controller } from "stimulus";

export default class extends Controller {
  static outlets = ["gray-element", "green-element"];
  connect() {}
  mouseOver(event) {
    const stageElementId = event.target.getAttribute("data-name-stage-id");
    const arrowElementId = event.target.getAttribute("data-arrow-stage-id");
    const linkElementId = event.target.getAttribute("data-link-stage-id");
    if (event.target.getAttribute("data-color") === "green") {
      if (stageElementId) {
        document
          .querySelector(`[data-arrow-stage-id="${stageElementId}"]`)
          .classList.add("!border-l-auxiliary-palette-green-down");
      }
      if (arrowElementId) {
        event.target.classList.add("!text-auxiliary-palette-green");
        const stageName = document.querySelector(
          `[data-name-stage-id="${arrowElementId}"]`
        );
        stageName.parentNode.classList.add("!bg-auxiliary-palette-green-down");
        stageName.classList.add("!text-auxiliary-palette-green");
      }
      if (linkElementId) {
        document
          .querySelector(`[data-arrow-stage-id="${linkElementId}"]`)
          .classList.add("!border-l-auxiliary-palette-green-down");
      }
    } else if (event.target.getAttribute("data-color") === "gray") {
      if (stageElementId) {
        document
          .querySelector(`[data-arrow-stage-id="${stageElementId}"]`)
          .classList.add("!border-l-gray-200");
      }
      if (arrowElementId) {
        const stageName = document.querySelector(
          `[data-name-stage-id="${arrowElementId}"]`
        );
        stageName.parentNode.classList.add("!bg-gray-200");
      }
      if (linkElementId) {
        document
          .querySelector(`[data-arrow-stage-id="${linkElementId}"]`)
          .classList.add("!border-l-gray-200");
      }
    }
  }
  mouseOut(event) {
    const stageElementId = event.target.getAttribute("data-name-stage-id");
    const arrowElementId = event.target.getAttribute("data-arrow-stage-id");
    const linkElementId = event.target.getAttribute("data-link-stage-id");
    if (event.target.getAttribute("data-color") === "green") {
      if (stageElementId) {
        document
          .querySelector(`[data-arrow-stage-id="${stageElementId}"]`)
          .classList.remove("!border-l-auxiliary-palette-green-down");
      }
      if (arrowElementId) {
        event.target.classList.remove("!text-auxiliary-palette-green");
        const stageName = document.querySelector(
          `[data-name-stage-id="${arrowElementId}"]`
        );
        stageName.parentNode.classList.remove(
          "!bg-auxiliary-palette-green-down"
        );
        stageName.classList.remove("!text-auxiliary-palette-green");
      }
      if (linkElementId) {
        document
          .querySelector(`[data-arrow-stage-id="${linkElementId}"]`)
          .classList.remove("!border-l-auxiliary-palette-green-down");
      }
    } else if (event.target.getAttribute("data-color") === "gray") {
      if (stageElementId) {
        document
          .querySelector(`[data-arrow-stage-id="${stageElementId}"]`)
          .classList.remove("!border-l-gray-200");
      }
      if (arrowElementId) {
        const stageName = document.querySelector(
          `[data-name-stage-id="${arrowElementId}"]`
        );
        stageName.parentNode.classList.remove("!bg-gray-200");
      }
      if (linkElementId) {
        document
          .querySelector(`[data-arrow-stage-id="${linkElementId}"]`)
          .classList.remove("!border-l-gray-200");
      }
    }
  }
}
