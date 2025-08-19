import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    amountInCents: Number,
    currency: String,
  };

  connect() {
    this.element.textContent = this.formatCurrency(
      this.amountInCentsValue,
      this.currencyValue
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
