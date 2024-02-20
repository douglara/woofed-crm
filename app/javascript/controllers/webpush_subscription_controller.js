import { Controller } from "stimulus"
import { FetchRequest } from '@rails/request.js'

export default class extends Controller {
  static values = {
    url: String,
    vapidPublicKey: Array
  }

  connect() {
    const vapidPublicKey = new Uint8Array(this.vapidPublicKeyValue);
    const url = this.urlValue
    if (navigator.serviceWorker) {
      navigator.serviceWorker.register('/service_worker.js')
      .then(function(reg) {
        navigator.serviceWorker.ready.then((serviceWorkerRegistration) => {
          serviceWorkerRegistration.pushManager
          .subscribe({
            userVisibleOnly: true,
            applicationServerKey: vapidPublicKey
          }).then(async function (sub) {
            const request = new FetchRequest('post',
              url,
              {
                body: JSON.stringify(sub)
              }
            )
            const response = await request.perform()
          });
        });
      });
    }
    // Otherwise, no push notifications :(
    else {
      console.error('Service worker is not supported in this browser');
    }
  }

}
