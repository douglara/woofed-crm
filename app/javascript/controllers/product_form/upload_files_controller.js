import { Controller } from "stimulus";
import UploadFile from "./upload_file";

export default class extends Controller {
  static targets = ["fileInput", "dragAlert"];
  static values = {
    acceptedTypes: Array,
  };

  connect() {
    this.eventListenerDragAndDrop("add");
  }

  disconnect() {
    this.eventListenerDragAndDrop("remove");
  }

  eventListenerDragAndDrop(state) {
    if (state === "add") {
      this.element.addEventListener("dragover", this.preventDragDefaults);
      this.element.addEventListener("dragenter", this.preventDragDefaults);
      this.element.addEventListener("dragleave", this.preventDragDefaults);
    } else {
      this.element.removeEventListener("dragover", this.preventDragDefaults);
      this.element.removeEventListener("dragenter", this.preventDragDefaults);
      this.element.removeEventListener("dragleave", this.preventDragDefaults);
    }
  }
  preventDragDefaults(event) {
    event.preventDefault();
    event.stopPropagation();
  }
  showDragAlert(event) {
    this.lastTarget = event.target;
    this.dragAlertTarget.style.display = "flex";
  }
  removeDragAlert(event) {
    if (event.target === this.lastTarget || event.target === document) {
      this.dragAlertTarget.style.display = "none";
    }
  }
  trigger(event) {
    event.stopPropagation();
    this.fileInputTarget.click();
  }
  acceptFiles(event) {
    event.preventDefault();
    this.dragAlertTarget.style.display = "none";
    const files = event.dataTransfer
      ? event.dataTransfer.files
      : event.target.files;
    [...files].forEach((file) => {
      new UploadFile(
        file,
        this.fileInputTarget,
        this.acceptedTypesValue
      ).process();
    });
  }
  removeFile(event) {
    const divToDelete = event.target.closest('[id^="upload"]');
    divToDelete.remove();
  }
}
