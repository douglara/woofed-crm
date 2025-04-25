import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["chatwootEmbedLink"];
  static values = { url: String };
  connect() {
    if (!this.isChatwootEmbedPage) {
      const contactId = sessionStorage.getItem("chatwoot_contact_id");

      if (contactId) {
        this.chatwootEmbedLinkTarget.setAttribute(
          "href",
          this.chatwootEmbedLink(contactId)
        );
        this.element.classList.remove("hidden");
      }
    }
  }
  removeNotificationBar(event) {
    event.preventDefault();
    sessionStorage.removeItem("chatwoot_contact_id");
    this.element.remove();
  }
  chatwootEmbedLink(contactId) {
    return this.urlValue.replace(":contact_id", contactId);
  }
  get isChatwootEmbedPage() {
    const iframes = document.querySelectorAll("iframe");
    const hasChatwootIframe = Array.from(iframes).some(
      (iframe) => iframe.src && iframe.src.includes("chatwoot_embed")
    );
    return hasChatwootIframe;
  }
}
