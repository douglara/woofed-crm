import { Controller } from "stimulus";

export default class extends Controller {
  redirect(event) {
    if (this.isInIframe) {
      event.preventDefault();
      const link = event.currentTarget.href;
      window.top.location.href = link;
    }
  }
  get isInIframe() {
    return window.self !== window.top;
  }
}
