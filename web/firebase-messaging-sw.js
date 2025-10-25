console.log('[firebase-messaging-sw.js] Service worker loading...');

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: "AIzaSyDxJ8aMKdXLn3gs9Zs0yc_4CkU5-kNYcP8",
  authDomain: "urchat-a5.firebaseapp.com",
  projectId: "urchat-a5",
  storageBucket: "urchat-a5.appspot.com",
  messagingSenderId: "980678477813",
  appId: "1:980678477813:web:2499995c25fe1cde2b02bc"
};

console.log('[firebase-messaging-sw.js] Initializing Firebase...');

try {
  firebase.initializeApp(firebaseConfig);
  console.log('[firebase-messaging-sw.js] Firebase initialized successfully');
} catch (error) {
  console.error('[firebase-messaging-sw.js] Firebase initialization failed:', error);
}

const messaging = firebase.messaging();

// Enhanced background message handler
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);
  
  // Extract notification data with better fallbacks
  const chatId = payload.data?.chatId || 'default';
  const chatName = payload.data?.chatName || payload.notification?.title || 'URChat';
  const sender = payload.data?.sender || 'Someone';
  const message = payload.data?.message || payload.notification?.body || 'New message';
  const isGroup = payload.data?.isGroup === 'true';
  
  console.log('[firebase-messaging-sw.js] Creating notification for chat:', chatName);
  
  // Create unique tag for each chat to prevent overwriting
  const notificationTag = `urchat-${chatId}`;
  const notificationTitle = isGroup ? chatName : sender;
  const notificationBody = isGroup ? `${sender}: ${message}` : message;
  
  const notificationOptions = {
    body: notificationBody,
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    tag: notificationTag, // Unique tag per chat
    data: {
      ...payload.data,
      chatId: chatId,
      chatName: chatName,
      timestamp: Date.now()
    },
    requireInteraction: false, // Set to false for better UX
    actions: [
      {
        action: 'open',
        title: 'Open Chat'
      },
      {
        action: 'close',
        title: 'Close'
      }
    ],
    // Add vibration pattern for mobile devices
    vibrate: [200, 100, 200]
  };

  // Show the notification
  return self.registration.showNotification(notificationTitle, notificationOptions)
    .then(() => {
      console.log('[firebase-messaging-sw.js] Browser notification shown successfully for:', chatName);
    })
    .catch(error => {
      console.error('[firebase-messaging-sw.js] Failed to show browser notification:', error);
    });
});

// Enhanced push event handler for foreground messages
self.addEventListener('push', (event) => {
  console.log('[firebase-messaging-sw.js] Push event received');
  
  let payload;
  try {
    if (event.data) {
      payload = event.data.json();
    } else {
      // Handle cases where data might be in different format
      payload = {};
    }
  } catch (error) {
    console.error('[firebase-messaging-sw.js] Error parsing push data:', error);
    payload = {};
  }
  
  console.log('[firebase-messaging-sw.js] Push payload:', payload);
  
  const chatId = payload.data?.chatId || payload.fcmMessageId || 'default';
  const chatName = payload.data?.chatName || payload.notification?.title || 'URChat';
  const sender = payload.data?.sender || 'Someone';
  const message = payload.data?.message || payload.notification?.body || 'New message';
  const isGroup = payload.data?.isGroup === 'true';
  
  const notificationTag = `urchat-${chatId}`;
  const notificationTitle = isGroup ? chatName : sender;
  const notificationBody = isGroup ? `${sender}: ${message}` : message;
  
  const notificationOptions = {
    body: notificationBody,
    icon: '/icons/icon-192x192.png',
    badge: '/icons/badge-72x72.png',
    tag: notificationTag,
    data: {
      ...payload.data,
      chatId: chatId,
      chatName: chatName,
      timestamp: Date.now()
    },
    requireInteraction: false,
    actions: [
      {
        action: 'open',
        title: 'Open Chat'
      }
    ],
    vibrate: [200, 100, 200]
  };
  
  event.waitUntil(
    self.registration.showNotification(notificationTitle, notificationOptions)
      .then(() => {
        console.log('[firebase-messaging-sw.js] Push notification shown:', chatName);
      })
      .catch(error => {
        console.error('[firebase-messaging-sw.js] Failed to show push notification:', error);
      })
  );
});

// Enhanced notification click handler
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification);
  
  event.notification.close();
  
  const chatId = event.notification.data?.chatId;
  const action = event.action;
  
  console.log('[firebase-messaging-sw.js] Action:', action, 'Chat ID:', chatId);
  
  if (action === 'close') {
    console.log('[firebase-messaging-sw.js] Notification closed by user');
    return;
  }
  
  // Default action is 'open'
  const urlToOpen = chatId ? `/?chatId=${chatId}` : '/';
  
  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then((clientList) => {
      // Try to focus an existing window
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          console.log('[firebase-messaging-sw.js] Focusing existing window');
          
          // Send message to open specific chat
          if (chatId && client.postMessage) {
            client.postMessage({
              type: 'OPEN_CHAT',
              chatId: chatId
            });
          }
          
          return client.focus();
        }
      }
      
      // If no existing window, open a new one
      if (clients.openWindow) {
        console.log('[firebase-messaging-sw.js] Opening new window');
        return clients.openWindow(urlToOpen);
      }
    })
  );
});

self.addEventListener('message', (event) => {
  console.log('[firebase-messaging-sw.js] Received message from app:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

console.log('[firebase-messaging-sw.js] Service worker setup complete');