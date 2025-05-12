import { Controller } from "stimulus";
import DateRangePicker from "daterangepicker";
import moment from "moment";
import "moment/locale/pt-br";

export default class extends Controller {
  static targets = ["dateRangeForm"];
  connect() {
    moment.locale("pt-br");
    this.dateRangePicker = new DateRangePicker(this.dateRangeFormTarget, {
      locale: {
        format: "DD/MM/YYYY",
      },
      showDropdowns: true,
      showWeekNumbers: true,
      ranges: {
        Today: [moment(), moment()],
        Yesterday: [moment().subtract(1, "days"), moment().subtract(1, "days")],
        "Last 7 Days": [moment().subtract(6, "days"), moment()],
        "Last 30 Days": [moment().subtract(29, "days"), moment()],
        "This Month": [moment().startOf("month"), moment().endOf("month")],
        "Last Month": [
          moment().subtract(1, "month").startOf("month"),
          moment().subtract(1, "month").endOf("month"),
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
}
