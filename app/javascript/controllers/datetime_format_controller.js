import { Controller } from "stimulus";
import moment from "moment-timezone";
import "moment/min/locales";
import "moment-timezone/node_modules/moment/locale/es";
import "moment-timezone/node_modules/moment/locale/pt-br";
import { getBrowserLocale, getTimeZone } from "../utils/locale";

export default class extends Controller {
  static values = {
    date: String,
    type: String,
    locale: String,
  };

  connect() {
    const date = this.dateInTimezone;
    this.setMomentJsLocale();
    this.element.textContent = this.formattedDate(date);
    this.updateRealTime();
  }

  disconnect() {
    clearInterval(this.updateInterval);
  }

  get dateInTimezone() {
    return moment.tz(this.dateValue, getTimeZone());
  }

  updateRealTime() {
    if (this.typeValue === "distance") {
      this.updateInterval = setInterval(() => {
        const updatedDate = moment.tz(this.dateValue, getTimeZone());
        this.setMomentJsLocale();
        this.element.textContent = updatedDate.fromNow(true);
      }, 60000);
    }
  }

  formattedDate(date) {
    switch (this.typeValue) {
      case "short":
        return date.format("DD/MM/YY HH:mm");
      case "distance":
        return date.fromNow(true);
      case "compact":
        return date.format("DD MMM HH:mm");
      default:
        return date.format("LLL");
    }
  }

  get locale() {
    return (
      this.localeValue && this.localeValue.trim() !== ""
        ? this.localeValue
        : getBrowserLocale()
    )
      .toLowerCase()
      .replace("_", "-");
  }

  setMomentJsLocale() {
    const supportedLocales = ["pt-br", "es", "en"];
    moment.locale(supportedLocales.includes(this.locale) ? this.locale : "en");
  }
}
