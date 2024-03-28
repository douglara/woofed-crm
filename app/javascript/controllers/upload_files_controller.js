import { Controller } from "stimulus";
import { DirectUpload } from "@rails/activestorage";

export default class extends Controller {
  static values = {
    xmarkSvgUrl: String,
  };
  static targets = ["fileInput", "dragAlert"];

  connect(e) {
    this.element.addEventListener("dragover", this.preventDragDefaults);
    this.element.addEventListener("dragenter", this.preventDragDefaults);
    this.element.addEventListener("dragleave", this.preventDragDefaults);
  }

  disconnect() {
    this.element.removeEventListener("dragover", this.preventDragDefaults);
    this.element.removeEventListener("dragenter", this.preventDragDefaults);
    this.element.addEventListener("dragleave", this.preventDragDefaults);
  }
  preventDragDefaults(event) {
    event.preventDefault();
    event.stopPropagation();
  }
  showDragAlert(e) {
    this.lastTarget = e.target;
    this.dragAlertTarget.style.display = "flex";
  }
  removeDragAlert(e) {
    if (e.target === this.lastTarget || e.target === document) {
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
      new Upload(file, this.xmarkSvgUrlValue, this.fileInputTarget).process();
      // this.uploadFile(file);
    });
  }
  removeFile(event) {
    const divToDelete = event.target.closest('[id^="upload"]');
    divToDelete.remove();
  }
}
class Upload {
  constructor(file, xmarkSvgUrl, fileInput) {
    this.directUpload = new DirectUpload(
      file,
      "/rails/active_storage/direct_uploads",
      this
    );
    this.xmarkSvgUrl = xmarkSvgUrl;
    this.fileInput = fileInput;
  }

  process() {
    const fileWrapper = this.insertUpload();
    this.directUpload.create((error, blob) => {
      if (error) {
        console.log(error);
        fileWrapper.remove();
      } else {
        this.createHiddenBlobInput(blob, this.directUpload.id);
      }
    });
  }

  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress", (event) =>
      this.updateProgress(event)
    );
  }
  updateProgress(event) {
    const percentage = (event.loaded / event.total) * 100;
    const progress = document.querySelector(
      `#upload_${this.directUpload.id} .progress-wrapper .progress-bar`
    );
    progress.style.width = `${percentage}%`;
  }
  createHiddenBlobInput(blob, uploadId) {
    const input = document.createElement("input");
    const inputWrapper = document.getElementById(`upload_${uploadId}`);
    input.type = "hidden";
    input.name = this.fileInput.name;
    input.value = blob.signed_id;
    inputWrapper.appendChild(input);
    return input;
  }
  insertUpload() {
    const fileWrapper = document.createElement("div");
    const fileName = document.createElement("p");
    const fileInfoWrapper = document.createElement("div");
    const fileThumb = document.createElement("img");
    const linkThumb = document.createElement("a");
    const iconDelete = `<div class="p-2.5 cursor-pointer" data-action="click->upload-files#removeFile"><img src="${this.xmarkSvgUrl}" alt="" class="w-4" ></div>`;
    const progress = `<div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700 flex-1 progress-wrapper">
    <div class="bg-brand-palette-03 h-2.5 rounded-full progress-bar" style="width: 0%"></div>
  </div>`;
    let reader = new FileReader();
    reader.readAsDataURL(this.directUpload.file);
    reader.onloadend = function () {
      if (reader.result !== null) {
        fileInfoWrapper.setAttribute("data-controller", "lightbox");
        fileThumb.src = reader.result;
        linkThumb.href = reader.result;
      } else {
        fileName.textContent = "Error";
      }
    };

    fileWrapper.id = `upload_${this.directUpload.id}`;
    fileWrapper.className =
      "p-1 pr-2 border border-light-palette-p3 rounded-lg flex items-center gap-10";
    fileName.className =
      "text-dark-gray-palette-p1 typography-text-m-lh150 w-56 truncate";
    fileThumb.className = "w-10 h-10 rounded-lg object-cover";
    linkThumb.className = "flex gap-4 items-center";
    fileName.textContent = this.directUpload.file.name;
    linkThumb.appendChild(fileThumb);
    linkThumb.appendChild(fileName);
    fileInfoWrapper.appendChild(linkThumb);
    fileWrapper.appendChild(fileInfoWrapper);
    fileWrapper.insertAdjacentHTML("beforeend", progress);
    fileWrapper.insertAdjacentHTML("beforeend", iconDelete);
    this.addFileToUploadList(fileWrapper);

    return fileWrapper;
  }
  addFileToUploadList(file) {
    const uploadList = document.querySelector("#uploads");
    uploadList.appendChild(file);
  }
}
