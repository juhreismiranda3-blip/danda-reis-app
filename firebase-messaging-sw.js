/* Service worker do Danda Reis — recebe as notificações com o app fechado. */
importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDLjJ8qNxxt2BcQSU4CS0flQhXbEPNojwc",
  authDomain: "danda-reis.firebaseapp.com",
  projectId: "danda-reis",
  storageBucket: "danda-reis.firebasestorage.app",
  messagingSenderId: "616739127471",
  appId: "1:616739127471:web:5b59137befa768ab2c545a"
});

var messaging = firebase.messaging();
var APP = '/danda-reis-app/';

messaging.onBackgroundMessage(function (payload) {
  var d = payload.data || {};
  self.registration.showNotification(d.title || 'Danda Reis', {
    body: d.body || '',
    icon: d.icon || (APP + 'icon.png'),
    badge: APP + 'icon.png',
    tag: 'danda-' + Date.now(),
    data: { link: d.link || APP }
  });
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var link = (event.notification.data && event.notification.data.link) || APP;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].url.indexOf(APP) >= 0 && 'focus' in list[i]) return list[i].focus();
      }
      if (clients.openWindow) return clients.openWindow(link);
    })
  );
});
