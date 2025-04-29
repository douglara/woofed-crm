import { Controller } from "stimulus";

export default class extends Controller {
  redirect(event) {
    if (this.isEmbedPage) {
      event.preventDefault();
      const conversationLink = event.currentTarget.href;
      window.top.location.href = conversationLink;
    }
  }
  get isEmbedPage() {
    return window.self !== window.top;
  }
}
