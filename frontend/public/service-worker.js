// Service Worker for AdsyClub PWA
const CACHE_VERSION = "adsyclub-v2"; // Incrementing cache version
const STATIC_CACHE = `${CACHE_VERSION}-static`;
const DYNAMIC_CACHE = `${CACHE_VERSION}-dynamic`;
const ASSETS_CACHE = `${CACHE_VERSION}-assets`;

const STATIC_URLS_TO_CACHE = [
  "/",
  "/index.html",
  "/manifest.json",
  "/static/frontend/favicon.png",
  // Add critical UI resources that should be available offline
];

const ASSETS_TO_CACHE = [
  // Images and assets that make the site look good offline
  "/static/frontend/icons/icon-192x192.png",
  "/static/frontend/icons/icon-512x512.png",
];

// Install event - cache essential assets in different caches
self.addEventListener("install", (event) => {
  event.waitUntil(
    Promise.all([
      // Cache static resources that are critical for the app shell
      caches.open(STATIC_CACHE).then((cache) => {
        console.log("Caching app shell resources");
        return cache.addAll(STATIC_URLS_TO_CACHE);
      }),

      // Cache assets that improve the offline experience
      caches.open(ASSETS_CACHE).then((cache) => {
        console.log("Caching app assets");
        return cache.addAll(ASSETS_TO_CACHE);
      }),
    ]).then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener("activate", (event) => {
  const currentCaches = [STATIC_CACHE, DYNAMIC_CACHE, ASSETS_CACHE];

  event.waitUntil(
    caches
      .keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (!currentCaches.includes(cacheName)) {
              console.log("Deleting old cache:", cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        console.log("Service Worker now controls all clients");
        return self.clients.claim();
      })
  );
});

// Helper function to determine if request should be cached
const shouldCache = (url) => {
  // Define patterns for URLs that should be cached
  const cachePatterns = [
    /\.(jpe?g|png|gif|svg|webp|ico)$/i, // Images
    /\.(css|js)$/i, // Static assets
    /^https:\/\/adsyclub\.com\//i, // Main domain content
    /^https:\/\/api\.adsyclub\.com\//i, // API responses (if applicable)
  ];

  return cachePatterns.some((pattern) => pattern.test(url));
};

// Network-first strategy with cache fallback for dynamic content
const networkFirst = async (request) => {
  try {
    const networkResponse = await fetch(request);

    // If response is valid and should be cached, store in dynamic cache
    if (networkResponse.ok && shouldCache(request.url)) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    // If network fails, try from cache
    const cachedResponse = await caches.match(request);

    if (cachedResponse) {
      return cachedResponse;
    }

    // If it's an HTML request, return the offline page
    if (request.headers.get("Accept").includes("text/html")) {
      return caches.match("/offline.html");
    }

    throw error;
  }
};

// Cache-first strategy for static assets
const cacheFirst = async (request) => {
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }

  try {
    const networkResponse = await fetch(request);

    if (networkResponse.ok) {
      const cache = await caches.open(ASSETS_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    console.error("Cache-first fetch failed:", error);
    throw error;
  }
};

// Improved fetch event handling with different strategies
self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  // Skip non-GET requests
  if (event.request.method !== "GET") {
    return;
  }

  // Skip browser extensions and chrome-extension requests
  if (url.protocol === "chrome-extension:") {
    return;
  }

  // Use cache-first for static assets
  if (
    event.request.url.match(/\.(jpe?g|png|gif|svg|webp|ico|css|js)$/i) ||
    event.request.url.includes("/static/")
  ) {
    event.respondWith(cacheFirst(event.request));
    return;
  }

  // Use network-first for everything else (API calls, HTML pages)
  event.respondWith(networkFirst(event.request));
});

// Handle push notifications when app is installed
self.addEventListener("push", (event) => {
  let data = { title: "New Notification", body: "Something new happened!" };

  try {
    if (event.data) {
      data = event.data.json();
    }
  } catch (error) {
    console.error("Error parsing push notification data:", error);
  }

  const options = {
    body: data.body,
    icon: "/static/frontend/icons/icon-192x192.png",
    badge: "/static/frontend/icons/badge-72x72.png",
    vibrate: [100, 50, 100],
    data: {
      url: data.url || "/",
    },
    actions: [
      {
        action: "open",
        title: "View",
      },
    ],
  };

  event.waitUntil(self.registration.showNotification(data.title, options));
});

// Handle notification click
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  if (event.action === "open" || !event.action) {
    event.waitUntil(
      clients.matchAll({ type: "window" }).then((windowClients) => {
        // Check if there is already a window/tab open with the target URL
        for (let client of windowClients) {
          if (client.url === event.notification.data.url && "focus" in client) {
            return client.focus();
          }
        }
        // If not, open a new window
        if (clients.openWindow) {
          return clients.openWindow(event.notification.data.url);
        }
      })
    );
  }
});
