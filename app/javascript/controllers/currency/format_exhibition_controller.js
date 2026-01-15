import { Controller } from "@hotwired/stimulus";
import { getAccountCurrency } from "../../utils/locale";

export default class extends Controller {
  static values = {
    amountInCents: Number,
  };

  connect() {
    this.element.textContent = this.formatCurrency(
      this.amountInCentsValue,
      getAccountCurrency()
    );
  }

  formatCurrency(amountInCents, currencyCode) {
    const value = amountInCents / 100.0;

    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: currencyCode || "USD",
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value);
  }
}
