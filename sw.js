const CACHE = ‘nip-v1’;
const OFFLINE_URLS = [’/NOTINPARIS/index.html’];

self.addEventListener(‘install’, e => {
e.waitUntil(
caches.open(CACHE).then(c => c.addAll(OFFLINE_URLS))
);
self.skipWaiting();
});

self.addEventListener(‘activate’, e => {
e.waitUntil(
caches.keys().then(keys =>
Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
)
);
self.clients.claim();
});

self.addEventListener(‘fetch’, e => {
if(e.request.method !== ‘GET’) return;
e.respondWith(
fetch(e.request).catch(() =>
caches.match(e.request).then(r => r || caches.match(’/NOTINPARIS/index.html’))
)
);
});

// Push notifications
self.addEventListener(‘push’, e => {
const data = e.data ? e.data.json() : {};
e.waitUntil(
self.registration.showNotification(data.title || ‘NOT IN PARIS’, {
body: data.body || ‘’,
icon: ‘/NOTINPARIS/icon-192.png’,
badge: ‘/NOTINPARIS/icon-192.png’,
vibrate: [200, 100, 200],
data: data.url || ‘/NOTINPARIS/index.html’,
actions: [
{ action: ‘open’, title: ‘Aç’ },
{ action: ‘close’, title: ‘Kapat’ }
]
})
);
});

self.addEventListener(‘notificationclick’, e => {
e.notification.close();
if(e.action === ‘open’ || !e.action) {
e.waitUntil(clients.openWindow(e.notification.data));
}
});
