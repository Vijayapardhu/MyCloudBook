/* Firebase Cloud Messaging Service Worker (Web) */
/* Using compat libraries for broad FlutterFire compatibility */

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyCDO7PgSeKyTuJvgspGi_9ezQpbq5Qlg0U",
  authDomain: "mycloud-book.firebaseapp.com",
  databaseURL: "https://mycloud-book-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "mycloud-book",
  storageBucket: "mycloud-book.firebasestorage.app",
  messagingSenderId: "675109149421",
  appId: "1:675109149421:web:110133aaa3727ef72ecae4",
  measurementId: "G-7G1N6VMZWP"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'MyCloudBook';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {}
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});


