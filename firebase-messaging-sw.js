importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyDxJ8aMKdXLn3gs9Zs0yc_4CkU5-kNYcP8",
    authDomain: "urchat-a5.firebaseapp.com",
    projectId: "urchat-a5",
    storageBucket: "urchat-a5.appspot.com",
    messagingSenderId: "980678477813",
    appId: "1:980678477813:web:2499995c25fe1cde2b02bc"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message: ', payload);
    const notificationTitle = payload.notification ?.title || 'URChat';
    const notificationOptions = {
        body: payload.notification ?.body || 'New message',
        icon: '/icons/icon-192.png',
        data: payload.data
    };
    self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', (event) => {
    console.log('[firebase-messaging-sw.js] Notification click: ', event.notification.data);
    event.notification.close();

    const chatId = event.notification.data ?.chatId;
    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
            for (const client of clientList) {
                if ('focus' in client) return client.focus();
            }
            if (clients.openWindow) {
                return clients.openWindow(chatId ? '/?chatId=' + chatId : '/');
            }
        })
    );
});