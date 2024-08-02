import { Controller } from "stimulus";
import { FetchRequest } from "@rails/request.js";

export default class extends Controller {
  static values = { subscriptionsUrl: String };
  static targets = ["activateNotificationsBtn", "activateWebpushInfo"];

  connect() {
    if (Notification.permission === "granted") {
      this.removeBtnNotification();
    } else {
      this.activateNotificationsBtnTarget.classList.remove("hidden");
    }
  }

  showPermissionWebpushSubscription(e) {
    e.preventDefault();
    if (navigator.serviceWorker) {
      navigator.serviceWorker.register("/service-worker.js").then((reg) => {
        navigator.serviceWorker.ready.then((serviceWorkerRegistration) => {
          serviceWorkerRegistration.pushManager
            .subscribe({
              userVisibleOnly: true,
              applicationServerKey: this.#vapidPublicKey,
            })
            .then(async (sub) => {
              const request = new FetchRequest(
                "post",
                this.subscriptionsUrlValue,
                {
                  body: JSON.stringify(sub),
                }
              );
              await request.perform();
              this.removeBtnNotification();
            });
        });
      });
    }

    // Otherwise, no push notifications :(
    else {
      console.error("Service worker is not supported in this browser");
    }
  }
  removeBtnNotification() {
    this.activateNotificationsBtnTarget.remove();
    this.activateWebpushInfoTarget.classList.remove("hidden");
  }

  get #vapidPublicKey() {
    const encodedVapidPublicKey = document.querySelector(
      'meta[name="vapid-public-key"]'
    ).content;
    return this.#urlBase64ToUint8Array(encodedVapidPublicKey);
  }

  // VAPID public key comes encoded as base64 but service worker registration needs it as a Uint8Array
  #urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, "+")
      .replace(/_/g, "/");

    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }

    return outputArray;
  }
}
