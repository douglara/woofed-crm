import { Controller } from "stimulus";
import { DirectUpload } from "@rails/activestorage";

export default class extends Controller {
  static targets = ["fileInput", "preview"];
  connect() {}
  trigger(event) {
    event.stopPropagation();
    this.fileInputTarget.click();
  }
  acceptFiles(event) {
    event.preventDefault();
    const files = event.dataTransfer
      ? event.dataTransfer.files
      : event.target.files;
    [...files].forEach((file) => {
      this.uploadFile(file);
    });
  }
  removeFile(event) {
    const divToDelete = event.target.parentElement;
    divToDelete.remove();
  }

  insertAfter(el, referenceNode) {
    return referenceNode.parentNode.insertBefore(el, referenceNode.nextSibling);
  }

  // createHiddenInput() {
  //   const input = document.createElement("input");
  //   input.type = "hidden";
  //   input.name = this.fileInputTarget.name;
  //   // input.value = blob.signed_id
  //   this.insertAfter(input, this.fileInputTarget);
  //   return input;
  // }
  createHiddenBlobInput(blob, uploadId) {
    const input = document.createElement("input");
    const inputWrapper = document.getElementById(`upload_${uploadId}`);
    input.type = "hidden";
    input.name = this.fileInputTarget.name;
    input.value = blob.signed_id;

    inputWrapper.appendChild(input);
    return input;
  }

  // insertUpload(upload) {
  //   const fileUpload = document.createElement("div");
  //   fileUpload.textContent = upload.file.name;

  //   const uploadList = document.querySelector("#uploads");
  //   uploadList.appendChild(fileUpload);
  // }

  insertUpload(upload) {
    const fileWrapper = document.createElement("div");
    const fileName = document.createElement("p");
    const fileInfoWrapper = document.createElement("div");
    const fileThumb = document.createElement("img");
    const linkThumb = document.createElement("a");
    const deleteFile = document.createElement("div");
    const deleteDescription = `<p class="">Remove</p>`;
    // const iconDelete = `<i data-lucide="x"></i>`;
    fileInfoWrapper.setAttribute("data-controller", "lightbox");
    deleteFile.setAttribute("data-action", "click->upload-files#removeFile");
    deleteFile.className = "stroke-brand-palette-03";
    // deleteFile.setAttribute("data-lucide", "x");
    let reader = new FileReader();
    reader.onloadend = function () {
      fileThumb.src = reader.result;
      linkThumb.href = reader.result;
    };
    reader.readAsDataURL(upload.file);

    fileWrapper.id = `upload_${upload.id}`;
    fileWrapper.className =
      "p-1 pr-4 border border-light-palette-p3 rounded-lg flex items-center justify-between";
    fileName.className =
      "text-dark-gray-palette-p1 typography-text-m-lh150 max-w-[300px] truncate";
    fileThumb.className = "w-10 h-10 rounded-lg object-cover";
    linkThumb.className = "flex gap-4 items-center";
    // deleteFile.className = "stroke-brand-palette-03";
    deleteFile.textContent = "Remove";
    linkThumb.appendChild(fileThumb);
    linkThumb.appendChild(fileName);
    fileInfoWrapper.appendChild(linkThumb);
    deleteFile.className =
      "typography-text-r-lh150 cursor-pointer text-dark-gray-palette-p3 hover:text-dark-gray-palette-p2";

    fileName.textContent = upload.file.name;
    fileWrapper.appendChild(fileInfoWrapper);
    // deleteFile.insertAdjacentHTML("afterbegin", deleteDescription);
    // deleteFile.appendChild(iconDelete);
    fileWrapper.appendChild(deleteFile);

    // const progressWrapper = document.createElement("div");
    // progressWrapper.className =
    //   "relative h-4 overflow-hidden rounded-full bg-secondary w-[100%]";
    // fileUpload.appendChild(progressWrapper);

    // const progressBar = document.createElement("div");
    // progressBar.className = "progress h-full w-full flex-1 bg-primary";
    // progressBar.style = "transform: translateX(-100%);";
    // progressWrapper.appendChild(progressBar);

    const uploadList = document.querySelector("#uploads");
    uploadList.appendChild(fileWrapper);
  }
  uploadFile(file) {
    // let hiddenInput = this.createHiddenInput();
    const upload = new DirectUpload(
      file,
      "/rails/active_storage/direct_uploads"
    );
    const uploadId = upload.id;

    this.insertUpload(upload);
    upload.create((error, blob) => {
      if (error) {
        // Handle the error
      } else {
        // debugger;
        this.createHiddenBlobInput(blob, uploadId);
        // hiddenInput.value = blob.signed_id;
      }
    });
  }
}
