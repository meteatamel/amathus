const CACHE_NAME = 'amathus-offline-v3';

const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/main.dart.js',
  '/manifest.json',
  '/version.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/assets/FontManifest.json',
  '/assets/AssetManifest.bin',
  '/assets/AssetManifest.bin.json',
  '/assets/fonts/MaterialIcons-Regular.otf',
  '/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  '/assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf',
  '/assets/assets/launcher/icon.png',
  '/assets/shaders/ink_sparkle.frag',
  '/assets/shaders/stretch_effect.frag',
  '/canvaskit/canvaskit.js',
  '/canvaskit/canvaskit.wasm',
  '/canvaskit/chromium/canvaskit.js',
  '/canvaskit/chromium/canvaskit.wasm',
  '/canvaskit/webparagraph/canvaskit.js',
  '/canvaskit/webparagraph/canvaskit.wasm',
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      await Promise.all(
        PRECACHE_URLS.map(async (url) => {
          try {
            const response = await fetch(url, { cache: 'reload' });
            if (response && response.status === 200) {
              await cache.put(url, response);
            }
          } catch (_) {}
        })
      );
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((key) => key !== CACHE_NAME)
            .map((key) => caches.delete(key))
        )
      )
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') {
    return;
  }

  const url = new URL(req.url);
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    return;
  }

  event.respondWith(
    fetch(req)
      .then((res) => {
        if (res && (res.status === 200 || res.type === 'opaque')) {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(req, copy).catch(() => {});
          });
        }
        return res;
      })
      .catch(async () => {
        const exactMatch = await caches.match(req);
        if (exactMatch) {
          return exactMatch;
        }

        if (url.origin === self.location.origin && !url.pathname.startsWith('/api/')) {
          const pathMatch = await caches.match(url.pathname);
          if (pathMatch) {
            return pathMatch;
          }
          const ignoreSearchMatch = await caches.match(req, { ignoreSearch: true });
          if (ignoreSearchMatch) {
            return ignoreSearchMatch;
          }
        }

        if (req.mode === 'navigate') {
          const rootCached =
            (await caches.match('/index.html')) ||
            (await caches.match('/'));
          if (rootCached) {
            return rootCached;
          }
        }

        throw new Error('Offline and resource not in cache: ' + req.url);
      })
  );
});
