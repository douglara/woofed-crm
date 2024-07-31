import { Controller } from "stimulus";
import WaveSurfer from "wavesurfer.js";
import RecordPlugin from "wavesurfer.js/dist/plugins/record.esm.js";
import UploadFile from "./upload_file";

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
    acceptedTypes: Array,
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
      new UploadFile(
        file,
        this.fileInputTarget,
        this.pauseWaveSvgUrlValue,
        this.playWaveSvgUrlValue,
        this.acceptedTypesValue
      ).process();
    });
  }
  removeFile(event) {
    const divToDelete = event.target.closest('[id^="upload"]');
    divToDelete.remove();
  }

  configWaveRecord() {
    try {
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
    } catch (e) {}
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
      new UploadFile(
        audioFile,
        this.fileInputTarget,
        this.pauseWaveSvgUrlValue,
        this.playWaveSvgUrlValue,
        this.acceptedTypesValue
      ).process();
    });
  }
}
