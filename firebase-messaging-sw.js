// web/firebase-messaging-sw.js

console.log('[firebase-messaging-sw.js] Service worker loading...');

// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyDxJ8aMKdXLn3gs9Zs0yc_4CkU5-kNYcP8",
  authDomain: "urchat-a5.firebaseapp.com",
  projectId: "urchat-a5",
  storageBucket: "urchat-a5.appspot.com",
  messagingSenderId: "980678477813",
  appId: "1:980678477813:web:2499995c25fe1cde2b02bc"
};

console.log('[firebase-messaging-sw.js] Initializing Firebase...');

// Initialize Firebase
try {
  firebase.initializeApp(firebaseConfig);
  console.log('[firebase-messaging-sw.js] Firebase initialized successfully');
} catch (error) {
  console.error('[firebase-messaging-sw.js] Firebase initialization failed:', error);
}

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);
  
  const notificationTitle = payload.notification?.title || payload.data?.sender || 'URChat';
  const notificationBody = payload.notification?.body || payload.data?.message || 'New message';
  const chatId = payload.data?.chatId;
  
  console.log('[firebase-messaging-sw.js] Creating notification:', notificationTitle, notificationBody);
  
  const notificationOptions = {
    body: notificationBody,
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    tag: 'urchat-message',
    data: payload.data,
    requireInteraction: true,
    actions: [
      {
        action: 'open',
        title: 'Open Chat'
      },
      {
        action: 'close',
        title: 'Close'
      }
    ]
  };

  // Show the notification
  return self.registration.showNotification(notificationTitle, notificationOptions)
    .then(() => {
      console.log('[firebase-messaging-sw.js] Browser notification shown successfully');
    })
    .catch(error => {
      console.error('[firebase-messaging-sw.js] Failed to show browser notification:', error);
    });
});

// Handle foreground messages (when app is open)
self.addEventListener('push', (event) => {
  console.log('[firebase-messaging-sw.js] Push event received:', event);
  
  if (!event.data) {
    console.log('[firebase-messaging-sw.js] No data in push event');
    return;
  }
  
  try {
    const payload = event.data.json();
    console.log('[firebase-messaging-sw.js] Push payload:', payload);
    
    const notificationTitle = payload.notification?.title || payload.data?.sender || 'URChat';
    const notificationBody = payload.notification?.body || payload.data?.message || 'New message';
    
    const notificationOptions = {
      body: notificationBody,
      icon: '/icons/icon-192x192.png',
      badge: '/icons/badge-72x72.png',
      tag: 'urchat-message',
      data: payload.data,
      requireInteraction: true,
      actions: [
        {
          action: 'open',
          title: 'Open Chat'
        },
        {
          action: 'close',
          title: 'Close'
        }
      ]
    };
    
    event.waitUntil(
      self.registration.showNotification(notificationTitle, notificationOptions)
        .then(() => {
          console.log('[firebase-messaging-sw.js] Push notification shown successfully');
        })
        .catch(error => {
          console.error('[firebase-messaging-sw.js] Failed to show push notification:', error);
        })
    );
  } catch (error) {
    console.error('[firebase-messaging-sw.js] Error processing push event:', error);
  }
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification.data);
  
  event.notification.close();
  
  const chatId = event.notification.data?.chatId;
  const action = event.action;
  
  console.log('[firebase-messaging-sw.js] Action:', action, 'Chat ID:', chatId);
  
  if (action === 'close') {
    console.log('[firebase-messaging-sw.js] Notification closed');
    return;
  }
  
  if (chatId) {
    console.log('[firebase-messaging-sw.js] Opening chat:', chatId);
    
    event.waitUntil(
      clients.matchAll({
        type: 'window',
        includeUncontrolled: true
      }).then((clientList) => {
        // Get the current origin (domain) dynamically
        const currentOrigin = self.location.origin;
        console.log('[firebase-messaging-sw.js] Current origin:', currentOrigin);
        
        // Try to focus an existing window from the same origin
        for (const client of clientList) {
          if (client.url.startsWith(currentOrigin) && 'focus' in client) {
            console.log('[firebase-messaging-sw.js] Focusing existing window:', client.url);
            return client.focus().then(() => {
              // Send message to the focused window to open the chat
              client.postMessage({
                type: 'OPEN_CHAT',
                chatId: chatId
              });
            });
          }
        }
        
        // If no existing window, open a new one with the current origin
        if (clients.openWindow) {
          const chatUrl = `${currentOrigin}/?chatId=${chatId}`;
          console.log('[firebase-messaging-sw.js] Opening new window:', chatUrl);
          return clients.openWindow(chatUrl);
        }
      })
    );
  }
});

// Handle messages from the main app
self.addEventListener('message', (event) => {
  console.log('[firebase-messaging-sw.js] Received message from app:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'OPEN_CHAT') {
    console.log('[firebase-messaging-sw.js] Received OPEN_CHAT message:', event.data);
    // You can handle additional logic here if needed
  }
});

console.log('[firebase-messaging-sw.js] Service worker setup complete');