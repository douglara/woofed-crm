import { Controller } from "stimulus"

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
          }).then(async function(sub){
            const data = await fetch(url, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json'
              },
              body: JSON.stringify(sub)
            })
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
