import { Controller } from "stimulus";

export default class extends Controller {
  mouseOver(event) {
    const stageElementId = event.target.getAttribute("data-name-stage-id");
    const arrowElementId = event.target.getAttribute("data-arrow-stage-id");
    const linkElementId = event.target.getAttribute("data-link-stage-id");
    if (event.target.getAttribute("data-color") === "green") {
      if (stageElementId) {
        try {
          document
            .querySelector(`[data-arrow-stage-id="${stageElementId}"]`)
            .classList.add("!border-l-auxiliary-palette-green-down");
        } catch {}
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
        try {
          document
            .querySelector(`[data-arrow-stage-id="${linkElementId}"]`)
            .classList.add("!border-l-auxiliary-palette-green-down");
        } catch {}
      }
    } else if (event.target.getAttribute("data-color") === "gray") {
      if (stageElementId) {
        try {
          document
            .querySelector(`[data-arrow-stage-id="${stageElementId}"]`)
            .classList.add("!border-l-gray-400");
        } catch {}
      }
      if (arrowElementId) {
        const stageName = document.querySelector(
          `[data-name-stage-id="${arrowElementId}"]`
        );
        stageName.parentNode.classList.add("!bg-gray-400");
      }
      if (linkElementId) {
        try {
          document
            .querySelector(`[data-arrow-stage-id="${linkElementId}"]`)
            .classList.add("!border-l-gray-400");
        } catch {}
      }
    }
  }
  mouseOut(event) {
    const stageElementId = event.target.getAttribute("data-name-stage-id");
    const arrowElementId = event.target.getAttribute("data-arrow-stage-id");
    const linkElementId = event.target.getAttribute("data-link-stage-id");
    if (event.target.getAttribute("data-color") === "green") {
      if (stageElementId) {
        try {
          document
            .querySelector(`[data-arrow-stage-id="${stageElementId}"]`)
            .classList.remove("!border-l-auxiliary-palette-green-down");
        } catch {}
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
        try {
          document
            .querySelector(`[data-arrow-stage-id="${linkElementId}"]`)
            .classList.remove("!border-l-auxiliary-palette-green-down");
        } catch {}
      }
    } else if (event.target.getAttribute("data-color") === "gray") {
      if (stageElementId) {
        try {
          document
            .querySelector(`[data-arrow-stage-id="${stageElementId}"]`)
            .classList.remove("!border-l-gray-400");
        } catch {}
      }
      if (arrowElementId) {
        const stageName = document.querySelector(
          `[data-name-stage-id="${arrowElementId}"]`
        );
        stageName.parentNode.classList.remove("!bg-gray-400");
      }
      if (linkElementId) {
        try {
          document
            .querySelector(`[data-arrow-stage-id="${linkElementId}"]`)
            .classList.remove("!border-l-gray-400");
        } catch {}
      }
    }
  }
}
