import { Controller } from "stimulus";
import WaveSurfer from "wavesurfer.js";
import Hover from "wavesurfer.js/dist/plugins/hover.js";

export default class extends Controller {
  static values = {
    audioUrl: String,
    eventId: String,
    playSvgUrl: String,
    pauseSvgUrl: String,
    volumeHighSvgUrl: String,
    volumeMutedSvgUrl: String,
  };
  static targets = [
    "playBtn",
    "stopBtn",
    "playIcon",
    "volumeRange",
    "toggleMute",
    "volumeIcon",
    "speed1xButton",
    "speedHalfxButton",
    "speed2xButton",
    "duration",
    "loading",
  ];

  connect() {
    const wavesurfer = WaveSurfer.create({
      container: "#waveform" + this.eventIdValue,
      waveColor: "#E7E6EF",
      progressColor: "#CBC8DB",
      responsive: true,
      hideScrollbar: true,
      barWidth: 2,
      barRadius: 4,
      height: 77,
      dragToSeek: true,
      cursorColor: "#E7E6EF",
      cursorWidth: 2,
      url: this.audioUrlValue,
      plugins: [Hover.create()],
    });

    wavesurfer.on("ready", () => {
      this.loadingTarget.remove();
      document.getElementById("waveform" + this.eventIdValue).className =
        "w-full";
    });

    wavesurfer.on("finish", () => {
      this.playIconTarget.setAttribute("src", this.playSvgUrlValue);
    });

    this.playBtnTarget.onclick = () => {
      wavesurfer.playPause();
      this.togglePlayIcon();
    };

    this.speed1xButtonTarget.onclick = () => {
      this.setPlaybackRateAndSelectButtonWithAria(1, this.speed1xButtonTarget, wavesurfer);
    };
    this.speedHalfxButtonTarget.onclick = () => {
      this.setPlaybackRateAndSelectButtonWithAria(1.5, this.speedHalfxButtonTarget, wavesurfer);
    };
    this.speed2xButtonTarget.onclick = () => {
      this.setPlaybackRateAndSelectButtonWithAria(2, this.speed2xButtonTarget, wavesurfer);
    };

    this.volumeRangeTarget.oninput = () => {
      var volumeLevel = Number(this.volumeRangeTarget.value / 100);
      wavesurfer.setVolume(volumeLevel);
      this.toggleVolumeIcon(wavesurfer);
    };
    this.toggleMuteTarget.onclick = () => {
      var isMuted = this.toggleMuteTarget.ariaDisabled === "true";
      if (isMuted === true) {
        wavesurfer.setVolume(0);
        this.volumeRangeTarget.value = 0;
      } else {
        wavesurfer.setVolume(0.5);
        this.volumeRangeTarget.value = 50;
      }
      this.toggleMuteTarget.ariaDisabled = !isMuted;
      this.toggleVolumeIcon(wavesurfer);
    };
    wavesurfer.on("ready", () => {
      this.durationTarget.textContent = this.formatTime(
        wavesurfer.getDuration()
      );
    });
  }
  formatTime(time) {
    return [
      Math.floor((time % 3600) / 60), // minutes
      ("00" + Math.floor(time % 60)).slice(-2), // seconds
    ].join(":");
  }

  togglePlayIcon() {
    const newIconSrc = this.playIconTarget
      .getAttribute("src")
      .includes(this.playSvgUrlValue)
      ? this.pauseSvgUrlValue
      : this.playSvgUrlValue;
    this.playIconTarget.setAttribute("src", newIconSrc);
  }

  resetAllSpeedButtonAriaSelected() {
    this.element.querySelectorAll(".speed-wrapper button").forEach((btn) => {
      btn.ariaSelected = false;
    });
  }

  toggleVolumeIcon(wavesurfer) {
    var isMuted = wavesurfer.getVolume() === 0;
    if (isMuted === true) {
      this.volumeIconTarget.setAttribute("src", this.volumeMutedSvgUrlValue);
    } else {
      this.volumeIconTarget.setAttribute("src", this.volumeHighSvgUrlValue);
    }
  }
  setPlaybackRateAndSelectButtonWithAria(speed, button, wavesurfer) {
    this.resetAllSpeedButtonAriaSelected();
    wavesurfer.setPlaybackRate(speed);
    button.ariaSelected = true;
  }
}
