import { Controller } from "stimulus";
import IMask from "imask";

export default class extends Controller {
  connect() {
    // new IMask(this.element, {
    //   mask: "num",
    //   blocks: {
    //     num: {
    //       mask: Number,
    //       scale: 2,
    //       thousandsSeparator: ".",
    //       padFractionalZeros: true,
    //       normalizeZeros: true,
    //       radix: ",",
    //     },
    //   },
    // });
  }
}
