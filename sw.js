const CACHE_NAME = 'smart-lab-v2';
const urlsToCache = [
    '/',
    '/dashboard',
    '/smart_schedule',
    '/offline',
    '/static/js/offline-sync.js',
    '/manifest.json',
    '/static/icons/icon-192x192.png',  // تأكد من وجود الأيقونات
    '/static/icons/icon-512x512.png'
];

// إضافة واجهات API الأساسية للعمل دون اتصال
const apiUrlsToCache = [
    '/api/offline-data',
    '/api/labs',
    '/api/subjects'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => cache.addAll(urlsToCache))
            .catch(err => console.warn('فشل تخزين بعض الملفات:', err))
    );
});

self.addEventListener('fetch', event => {
    const url = new URL(event.request.url);
    
    // استراتيجية خاصة لواجهات API: محاولة الشبكة أولاً ثم العودة إلى التخزين المؤقت
    if (apiUrlsToCache.some(apiUrl => url.pathname.startsWith(apiUrl))) {
        event.respondWith(
            fetch(event.request)
                .then(response => {
                    const responseClone = response.clone();
                    caches.open(CACHE_NAME).then(cache => {
                        cache.put(event.request, responseClone);
                    });
                    return response;
                })
                .catch(() => caches.match(event.request))
        );
        return;
    }
    
    // للملفات العادية: تخزين مؤقت ثم الرجوع للشبكة
    event.respondWith(
        caches.match(event.request)
            .then(response => response || fetch(event.request))
            .catch(() => caches.match('/offline'))
    );
});

self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(keys => Promise.all(
            keys.map(key => {
                if (key !== CACHE_NAME) return caches.delete(key);
            })
        ))
    );
});