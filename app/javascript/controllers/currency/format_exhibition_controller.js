import { Controller } from "@hotwired/stimulus";
import { getAccountCurrency } from "../../utils/locale";

export default class extends Controller {
  static values = {
    amountInCents: Number,
  };

  connect() {
    this.element.textContent = this.formatCurrency(
      this.amountInCentsValue,
      getAccountCurrency(),
    );
  }

  formatCurrencyBeforeMorphRefresh(event) {
    const newElement = event.detail?.newElement;

    if (!newElement) return;

    const amount = newElement.getAttribute(
      "data-currency--format-exhibition-amount-in-cents-value",
    );

    if (!amount) return;

    newElement.textContent = this.formatCurrency(
      Number(amount),
      getAccountCurrency(),
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
