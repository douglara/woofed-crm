import { Controller } from "stimulus";
import IMask from "imask";

export default class extends Controller {
  connect() {
    this.formatExhibitionNumberField();
    this.configMaskField();
    this.prepareSubmit();
  }

  configMaskField() {
    new IMask(this.element, {
      mask: "num",
      blocks: {
        num: {
          mask: Number,
          scale: 2,
          thousandsSeparator: ".",
          padFractionalZeros: true,
          normalizeZeros: true,
          radix: ",",
        },
      },
    });
  }

  formatExhibitionNumberField() {
    this.element.value = this.formatToCurrencyNumber(this.element.value);
  }

  formatToCurrencyNumber(amount) {
    const parts = (amount / 100).toFixed(2).split(".");
    const integerPart = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    const decimalPart = parts[1];
    return integerPart + "," + decimalPart;
  }

  prepareSubmit() {
    const form = this.element.form;
    if (!form) return;

    form.addEventListener("submit", () => {
      const value = this.element.value;

      if (!value.includes(",")) {
        this.element.value = value + ",00";
      } else {
        this.element.value = value;
      }
    });
  }
}
