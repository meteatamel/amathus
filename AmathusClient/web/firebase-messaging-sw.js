importScripts('https://www.gstatic.com/firebasejs/11.6.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.6.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD_V4Joz-pXtBSU9LQ8srBc8BXtdfPYzys',
  authDomain: 'events-atamel.firebaseapp.com',
  projectId: 'events-atamel',
  storageBucket: 'events-atamel.firebasestorage.app',
  messagingSenderId: '1086570528700',
  appId: '1:1086570528700:web:8c30efa9f04507bf9675b9',
  measurementId: 'G-6KGJ0WKS78',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  // If FCM already included a notification payload, the browser displays it automatically.
  // Only manually show one for data-only payloads.
  if (payload && payload.notification) {
    return;
  }
  const data = (payload && payload.data) || {};
  const title = data.title || 'Cyprus Bicommunal News';
  const body = data.body || 'Your new 5-minute Cyprus news review is ready.';
  return self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'amathus-briefing',
    data: { url: data.url || '/' },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl =
    (event.notification && event.notification.data && event.notification.data.url) ||
    '/';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
    })
  );
});
