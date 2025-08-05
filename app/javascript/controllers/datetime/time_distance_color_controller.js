import { Controller } from "stimulus";
import moment from "moment-timezone";
import { getTimeZone } from "../../utils/locale";

export default class extends Controller {
  static values = {
    date: String,
  };

  connect() {
    this.updateColor();
    this.updateRealTime();
  }

  disconnect() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
    }
  }

  updateColor() {
    if (!this.hasDateValue) return;

    const now = moment.tz(getTimeZone());
    const date = moment.tz(this.dateValue, getTimeZone());

    const expired = date.isBefore(now);

    this.element.classList.toggle("color-fg-feedback-danger", expired);
    this.element.classList.toggle("color-fg-feedback-success", !expired);
  }

  updateRealTime() {
    this.updateInterval = setInterval(() => {
      this.updateColor();
    }, 60000);
  }
}
