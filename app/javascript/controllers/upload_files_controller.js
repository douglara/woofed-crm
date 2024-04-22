import { Controller } from "stimulus";
import { DirectUpload } from "@rails/activestorage";
import WaveSurfer from "wavesurfer.js";
import RecordPlugin from "wavesurfer.js/dist/plugins/record.esm.js";
import Hover from "wavesurfer.js/dist/plugins/hover.js";

export default class extends Controller {
  static targets = [
    "fileInput",
    "dragAlert",
    "micWave",
    "recordIcon",
    "micWaveWrapper",
    "progressRecord",
  ];
  static values = {
    pauseRecordSvgUrl: String,
    micSvgUrl: String,
    pauseWaveSvgUrl: String,
    playWaveSvgUrl: String,
  };

  connect() {
    this.configWaveRecord();
    this.eventListenerDragAndDrop("add");
  }

  disconnect() {
    this.eventListenerDragAndDrop("remove");
  }

  recordAudio() {
    if (this.record.isRecording() || this.record.isPaused()) {
      this.record.stopRecording();
      this.micWaveWrapperTarget.classList.add("hidden");
      this.recordIconTarget.src = this.micSvgUrlValue;
      return;
    }
    let recordDevice;

    RecordPlugin.getAvailableAudioDevices().then((devices) => {
      recordDevice = devices[0].deviceId;
    });
    this.record.startRecording({ recordDevice }).then(() => {
      this.micWaveWrapperTarget.classList.remove("hidden");
      this.recordIconTarget.src = this.pauseRecordSvgUrlValue;
    });
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
      new Upload(
        file,
        this.fileInputTarget,
        this.pauseWaveSvgUrlValue,
        this.playWaveSvgUrlValue
      ).process();
    });
  }
  removeFile(event) {
    const divToDelete = event.target.closest('[id^="upload"]');
    divToDelete.remove();
  }

  configWaveRecord() {
    const wavesurfer = WaveSurfer.create({
      container: this.micWaveTarget,
      waveColor: "#D9DEFF",
      progressColor: "#6756D6",
      height: 37,
      barHeight: 4,
    });
    this.record = wavesurfer.registerPlugin(
      RecordPlugin.create({
        scrollingWaveform: false,
        renderRecordedAudio: false,
      })
    );
    this.bindWaveRecordEvents();
  }
  bindWaveRecordEvents() {
    const updateProgress = (time) => {
      const formattedTime = [
        Math.floor((time % 3600000) / 60000),
        Math.floor((time % 60000) / 1000),
      ]
        .map((v) => (v < 10 ? "0" + v : v))
        .join(":");
      this.progressRecordTarget.textContent = formattedTime;
    };
    this.record.on("record-progress", (time) => {
      updateProgress(time);
    });

    this.record.on("record-end", (blob) => {
      const timestamp = new Date().getTime();
      const fileName = `${timestamp}.oga`;
      const audioFile = new File([blob], fileName, {
        type: "audio/ogg",
      });

      new Upload(
        audioFile,
        this.fileInputTarget,
        this.pauseWaveSvgUrlValue,
        this.playWaveSvgUrlValue
      ).process();
    });
  }
}
class Upload {
  constructor(file, fileInput, pauseSvg, playSvg) {
    this.directUpload = new DirectUpload(
      file,
      "/rails/active_storage/direct_uploads",
      this
    );
    this.fileInput = fileInput;
    this.pauseSvg = pauseSvg;
    this.playSvg = playSvg;
  }

  process() {
    const fileWrapper = this.insertUpload();
    const progressBar = fileWrapper.querySelector("#progressWrapper");

    if (this.isFileSizeExceeded()) {
      progressBar.remove();
      this.showErrorMessage(
        "The file exceeds the allowed size limit (40MB).",
        fileWrapper
      );
    } else {
      this.directUpload.create((error, blob) => {
        progressBar.remove();
        if (error) {
          this.showErrorMessage(error, fileWrapper);
        } else {
          if (this.fileTypeIs("audio")) {
            this.createWaveForm(fileWrapper);
          }
          this.createHiddenBlobInput(blob, this.directUpload.id);
        }
      });
    }
  }
  createWaveForm(fileWrapper) {
    const uploadInfo = fileWrapper.querySelector(
      `#upload_${this.directUpload.id}_info`
    );
    const waveWrapper = document.createElement("div");
    const wave = document.createElement("div");
    const audioDuration = document.createElement("p");
    waveWrapper.className = "flex items-center gap-2.5 justify-end";
    audioDuration.className =
      "typography-body-m-lh150 text-dark-gray-palette-p2";
    waveWrapper.appendChild(wave);
    waveWrapper.appendChild(audioDuration);
    uploadInfo.appendChild(waveWrapper);

    const reader = new FileReader();
    reader.readAsDataURL(this.directUpload.file);
    reader.onloadend = () => {
      const audioUrl = reader.result;
      const waveForm = WaveSurfer.create({
        container: wave,
        waveColor: "#D9DEFF",
        progressColor: "#6756D6",
        url: audioUrl,
        height: 42,
        barGap: 4,
        barRadius: 30,
        barWidth: 2,
        width: 412,
        cursorWidth: 0,
        plugins: [Hover.create()],
      });
      waveForm.on("finish", () => {
        playPauseBtn.querySelector("img").setAttribute("src", this.playSvg);
      });
      waveForm.on("ready", () => {
        audioDuration.textContent = this.formatTime(waveForm.getDuration());
      });
      const playPauseBtn = fileWrapper.querySelector("#playPauseBtn");
      playPauseBtn.classList.remove("pointer-events-none");
      playPauseBtn.onclick = (event) => {
        event.preventDefault();
        waveForm.playPause();
        this.togglePlayIcon(playPauseBtn.querySelector("img"));
      };
    };
  }
  formatTime(time) {
    return [
      Math.floor((time % 3600) / 60), // minutes
      ("00" + Math.floor(time % 60)).slice(-2), // seconds
    ].join(":");
  }
  togglePlayIcon(img) {
    const newIconSrc = img.getAttribute("src").includes(this.playSvg)
      ? this.pauseSvg
      : this.playSvg;
    img.setAttribute("src", newIconSrc);
  }
  isFileSizeExceeded() {
    const fileSize = this.directUpload.file.size;
    const fileSizeLimit = 41943040;
    return fileSize > fileSizeLimit;
  }
  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress", (event) =>
      this.updateProgress(event)
    );
  }
  updateProgress(event) {
    const percentage = (event.loaded / event.total) * 100;
    const progress = document.querySelector(
      `#upload_${this.directUpload.id}_info #progressWrapper #progressBar`
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
  }
  createAudioWrapper() {
    const fileWrapper = document.querySelector("#audioWrapper").cloneNode(true);
    const uploadInfo = fileWrapper.querySelector("#uploadInfo");
    const fileName = fileWrapper.querySelector("#fileName");
    fileWrapper.classList.remove("hidden");
    fileWrapper.id = `upload_${this.directUpload.id}`;
    uploadInfo.id = `upload_${this.directUpload.id}_info`;
    fileName.textContent = this.directUpload.file.name;
    this.addFileToUploadList(fileWrapper);
    return fileWrapper;
  }
  insertUpload() {
    let fileWrapper;
    if (this.fileTypeIs("audio")) {
      fileWrapper = this.createAudioWrapper();
    } else {
      fileWrapper = this.createFileWrapper();
    }
    return fileWrapper;
  }
  createFileWrapper() {
    const fileWrapper = document.querySelector("#fileWrapper").cloneNode(true);
    const uploadInfo = fileWrapper.querySelector("#uploadInfo");
    const fileName = fileWrapper.querySelector("#fileName");
    fileWrapper.classList.remove("hidden");
    fileWrapper.id = `upload_${this.directUpload.id}`;
    uploadInfo.id = `upload_${this.directUpload.id}_info`;
    fileName.textContent = this.directUpload.file.name;
    this.setLinkFileThumb(fileWrapper);
    this.addFileToUploadList(fileWrapper);
    return fileWrapper;
  }
  addFileToUploadList(file) {
    const uploadList = document.querySelector("#uploads");
    uploadList.appendChild(file);
  }
  setLinkFileThumb(fileWrapper) {
    let reader = new FileReader();
    const fileInfoWrapper = fileWrapper.querySelector("#fileInfoWrapper");
    const fileThumb = fileWrapper.querySelector("#fileThumb");
    const linkThumb = fileWrapper.querySelector("#linkThumb");

    reader.readAsDataURL(this.directUpload.file);
    reader.onloadend = () => {
      if (reader.result !== null && this.fileTypeIs("image")) {
        fileInfoWrapper.setAttribute("data-controller", "lightbox");
        fileThumb.src = reader.result;
        linkThumb.href = reader.result;
        linkThumb.classList.remove("pointer-events-none");
      }
    };
  }
  fileTypeIs(type) {
    const fileType = this.directUpload.file.type.split("/")[0];
    return fileType === type;
  }
  showErrorMessage(message, fileWrapper) {
    const uploadInfo = fileWrapper.querySelector(
      `#upload_${this.directUpload.id}_info`
    );
    fileWrapper.classList.replace(
      "border-light-palette-p3",
      "border-auxiliary-palette-red"
    );
    const messageError = `<p class='w-4/5 typography-text-m-lh150 text-auxiliary-palette-red truncate'>${message}</p>`;
    uploadInfo.insertAdjacentHTML("beforeend", messageError);
  }
}
