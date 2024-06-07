// self.addEventListener("push", async (event) => {
//   const data = await event.data.json();
//   event.waitUntil(Promise.all([showNotification(data)]));
// });

// async function showNotification({ title, options }) {
//   return self.registration.showNotification(title, options);
// }

// // self.addEventListener("notificationclick", (event) => {
// //   event.notification.close();

// //   const url = new URL(event.notification.data.path, self.location.origin).href;
// //   event.waitUntil(openURL(url));
// // });

// self.addEventListener("notificationclick", function (event) {
//   var url = event.notification.data.url;
//   event.notification.close();
//   event.waitUntil(clients.openWindow(url));
// });

// // async function openURL(url) {
// //   const clients = await self.clients.matchAll({ type: "window" });
// //   const focused = clients.find((client) => client.focused);

// //   if (focused) {
// //     await focused.navigate(url);
// //   } else {
// //     await self.clients.openWindow(url);
// //   }
// // }
// console.log("Aqui é o service worker");

// serviceworker.js
// The serviceworker context can respond to 'push' events and trigger
// notifications on the registration property
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
