import { Controller } from "stimulus";
import DateRangePicker from "daterangepicker";
import "moment-timezone/node_modules/moment/locale/es";
import "moment-timezone/node_modules/moment/locale/pt-br";
import moment from "moment-timezone";
import { getBrowserLocale, getBrowserTimeZone } from "../../utils/locale";

export default class extends Controller {
  static targets = ["dateRangeForm"];
  static values = {
    language: String,
  };

  connect() {
    this.setMomentJsLocale();
    const now = moment.tz(getBrowserTimeZone());
    const yesterday = now.clone().subtract(1, "days");
    const localeData = moment.localeData();

    this.dateRangePicker = new DateRangePicker(this.dateRangeFormTarget, {
      locale: {
        format: "YYYY/MM/DD",
        applyLabel: "Apply",
        cancelLabel: "Cancel",
        fromLabel: "From",
        toLabel: "To",
        customRangeLabel: "Custom",
        weekLabel: "W",
        daysOfWeek: localeData.weekdaysMin(),
        monthNames: localeData.months(),
        firstDay: localeData.firstDayOfWeek(),
      },
      showDropdowns: true,
      showWeekNumbers: true,
      ranges: {
        Today: [now.clone(), now.clone()],
        Yesterday: [yesterday.clone(), yesterday.clone()],
        "Last 7 Days": [now.clone().subtract(6, "days"), now.clone()],
        "Last 30 Days": [now.clone().subtract(29, "days"), now.clone()],
        "This Month": [
          now.clone().startOf("month"),
          now.clone().endOf("month"),
        ],
        "Last Month": [
          now.clone().subtract(1, "month").startOf("month"),
          now.clone().subtract(1, "month").endOf("month"),
        ],
      },
      buttonClasses:
        "inline-flex gap-2 items-center typography-body-900 rounded border-[1.5px] border-transparent h-8 px-3 ml-2 first:ml-0",
      applyButtonClasses: "btn-primary",
      cancelClass: "btn-secondary",
      opens: "left",
    });

    $(this.dateRangeFormTarget).on("apply.daterangepicker", () => {
      this.element.requestSubmit();
    });
  }

  disconnect() {
    if (this.dateRangePicker) {
      this.dateRangePicker.remove();
    }
  }

  get locale() {
    return (
      this.languageValue && this.languageValue.trim() !== ""
        ? this.languageValue
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
