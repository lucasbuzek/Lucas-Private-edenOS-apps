const CACHE = "seshat-local-v1";
const ASSETS = [
  "./", "./index.html", "./app.mjs", "./styles.css", "./manifest.webmanifest", "./icon.svg",
  "./src/domain/ledger.mjs", "./src/domain/queries.mjs", "./src/domain/catalogue.mjs",
  "./src/persistence/snapshot.mjs", "./src/persistence/browser-idb.mjs",
  "./fixtures/demo-inventory.mjs"
];
self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(ASSETS)));
  self.skipWaiting();
});
self.addEventListener("activate", event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key.startsWith("seshat-local-") && key !== CACHE).map(key => caches.delete(key)))));
  self.clients.claim();
});
self.addEventListener("fetch", event => {
  const req = event.request;
  if (req.method !== "GET" || new URL(req.url).origin !== self.location.origin) return;
  event.respondWith(fetch(req).then(response => {
    if (response.ok && (req.mode === "navigate" || ASSETS.some(path => new URL(path, self.location.href).href === req.url))) {
      const copy = response.clone();
      caches.open(CACHE).then(cache => cache.put(req, copy)).catch(() => {});
    }
    return response;
  }).catch(async () => {
    const cached = await caches.match(req);
    if (cached) return cached;
    if (req.mode === "navigate") return caches.match("./index.html");
    return Response.error();
  }));
});
