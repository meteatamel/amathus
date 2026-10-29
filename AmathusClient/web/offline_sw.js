const CACHE_NAME = 'amathus-offline-v16';

const ESSENTIAL_SHELL_URLS = [
  '/',
  '/index.html',
];

const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/flutter_bootstrap.js',
  '/main.dart.js',
  '/manifest.json',
  '/version.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/assets/FontManifest.json',
  '/assets/AssetManifest.bin',
  '/assets/AssetManifest.bin.json',
  '/assets/fonts/MaterialIcons-Regular.otf',
  '/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  '/assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf',
  '/assets/assets/launcher/icon.png',
  '/assets/shaders/ink_sparkle.frag',
  '/assets/shaders/stretch_effect.frag',
  '/canvaskit/chromium/canvaskit.js',
  '/canvaskit/chromium/canvaskit.wasm',
  '/canvaskit/canvaskit.js',
  '/canvaskit/canvaskit.wasm',
];

let precachePromise = null;

async function putInCacheWithPathnameAlias(cache, reqOrUrl, response) {
  if (!response || (response.status !== 200 && response.type !== 'opaque')) {
    return;
  }
  const reqUrl = typeof reqOrUrl === 'string' ? new URL(reqOrUrl, self.location.origin) : new URL(reqOrUrl.url);
  await cache.put(reqOrUrl, response.clone());
  if (
    reqUrl.origin === self.location.origin &&
    reqUrl.search &&
    !reqUrl.pathname.startsWith('/api/')
  ) {
    await cache.put(reqUrl.pathname, response.clone());
  }
}

function precacheAll() {
  if (precachePromise) {
    return precachePromise;
  }
  precachePromise = caches
    .open(CACHE_NAME)
    .then(async (cache) => {
      await Promise.all(
        PRECACHE_URLS.map(async (url) => {
          try {
            const existing = await cache.match(url);
            if (existing) {
              return;
            }
            const response = await fetch(url, { cache: 'no-cache' });
            if (response && response.status === 200) {
              await putInCacheWithPathnameAlias(cache, url, response);
            }
          } catch (_) {}
        })
      );
    })
    .finally(() => {
      precachePromise = null;
    });
  return precachePromise;
}

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      await Promise.all(
        ESSENTIAL_SHELL_URLS.map(async (url) => {
          try {
            const response = await fetch(url, { cache: 'no-cache' });
            if (response && response.status === 200) {
              await putInCacheWithPathnameAlias(cache, url, response);
            }
          } catch (_) {}
        })
      );
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const newCache = await caches.open(CACHE_NAME);
      const keys = await caches.keys();
      for (const key of keys) {
        if (key === CACHE_NAME) continue;
        try {
          const oldCache = await caches.open(key);
          const oldReqs = await oldCache.keys();
          for (const req of oldReqs) {
            try {
              const u = new URL(req.url);
              // Only carry over cached podcast audio & imageproxy across version bumps;
              // never copy old JS bundles or tree-shaken icon fonts.
              const isMediaCache =
                u.pathname.startsWith('/api/v1/overview/podcast/audio') ||
                u.pathname.startsWith('/api/v1/imageproxy');
              if (!isMediaCache) continue;
              const already = await newCache.match(req);
              if (!already) {
                const oldRes = await oldCache.match(req);
                if (oldRes) {
                  await newCache.put(req, oldRes);
                }
              }
            } catch (_) {}
          }
        } catch (_) {}
        await caches.delete(key);
      }
      await self.clients.claim();
      precacheAll();
    })()
  );
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'WARM_CACHE') {
    event.waitUntil(precacheAll());
  }
});

function isCacheFirstStaticAsset(pathname) {
  return (
    pathname.startsWith('/canvaskit/') ||
    pathname.startsWith('/icons/') ||
    pathname.startsWith('/assets/shaders/')
  );
}

function isDataApiRequest(pathname) {
  if (!pathname.startsWith('/api/')) return false;
  if (
    pathname.startsWith('/api/v1/overview/podcast/audio') ||
    pathname.startsWith('/api/v1/imageproxy')
  ) {
    return false;
  }
  return true;
}

async function matchFromCache(req, url) {
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

  return null;
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') {
    return;
  }

  const url = new URL(req.url);
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    return;
  }

  const browserOffline = self.navigator && self.navigator.onLine === false;

  // Never serve JSON data API calls from Service Worker or browser HTTP disk cache.
  // When offline, reject immediately so Dart controllers show the OfflineBanner + SharedPreferences cache.
  if (isDataApiRequest(url.pathname)) {
    if (browserOffline) {
      event.respondWith(Promise.reject(new Error('Offline')));
      return;
    }
    event.respondWith(fetch(req, { cache: 'no-store' }));
    return;
  }

  // When browser already knows it is offline, serve straight from CacheStorage without waiting on network timeouts.
  if (browserOffline) {
    event.respondWith(
      matchFromCache(req, url).then((cached) => {
        if (cached) {
          return cached;
        }
        return fetch(req);
      })
    );
    return;
  }

  // Cache-first for heavy static engine/font assets (CanvasKit WASM, icon fonts)
  if (url.origin === self.location.origin && isCacheFirstStaticAsset(url.pathname)) {
    event.respondWith(
      matchFromCache(req, url).then((cached) => {
        if (cached) {
          return cached;
        }
        return fetch(req).then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => {
              putInCacheWithPathnameAlias(cache, req, copy).catch(() => {});
            });
          }
          return res;
        });
      })
    );
    return;
  }

  // Network-first for app shell (index.html, main.dart.js, fonts, etc.) and media
  const fetchOpts = url.origin === self.location.origin ? { cache: 'no-cache' } : {};
  event.respondWith(
    fetch(req, fetchOpts)
      .then((res) => {
        if (res && (res.status === 200 || res.type === 'opaque')) {
          const copy = res.clone();
          caches.open(CACHE_NAME).then((cache) => {
            putInCacheWithPathnameAlias(cache, req, copy).catch(() => {});
          });
        }
        return res;
      })
      .catch(async () => {
        const cached = await matchFromCache(req, url);
        if (cached) {
          return cached;
        }
        throw new Error('Offline and resource not in cache: ' + req.url);
      })
  );
});
