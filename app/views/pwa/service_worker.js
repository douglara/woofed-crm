self.addEventListener("push", function (event) {
  var json = event.data.json();
  self.registration.showNotification(json.title, {
    body: json.body,
    icon: json.icon,
    data: {
      url: json.url,
    },
  });
});

self.addEventListener("notificationclick", function (event) {
  var url = event.notification.data.url;
  event.notification.close();
  event.waitUntil(clients.openWindow(url));
});
