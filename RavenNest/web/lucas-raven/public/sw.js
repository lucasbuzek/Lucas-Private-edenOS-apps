"use strict";
/* BIFROST Web/PWA asset shell. No API, secrets or app state is cached. */
const CACHE_NAME = "bifrost-pwa-remote-20261009-v1";
const STATIC = new Set(["/offline.html","/style.css","/app.js","/manifest.webmanifest","/icons/icon-192.png","/icons/icon-512.png"]);
const OFFLINE = "/offline.html";

async function safeStaticResponse(path) {
  const response = await fetch(path, {credentials: "same-origin", cache: "no-store"});
  // Never cache a redirected Cloudflare sign-in screen or cross-origin response.
  // A redirect can lead to a sign-in screen even on the same origin.
  // Cache only expected public static MIME types, never Access/auth HTML.
  if (!response.ok || response.redirected ||
      new URL(response.url).origin !== self.location.origin) {
    throw new Error("Static asset unavailable or redirected");
  }
  const expected = path.endsWith(".png") ? "image/png" :
    path.endsWith(".js") ? "javascript" :
    path.endsWith(".css") ? "text/css" :
    path.endsWith(".webmanifest") ? "json" : "text/html";
  const mime = (response.headers.get("Content-Type") || "").toLowerCase();
  if (!mime.includes(expected)) {
    throw new Error("Static asset MIME mismatch");
  }
  return response;
}

self.addEventListener("install", event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    // Static assets are best effort; the offline page must exist for graceful fallback.
    try {
      const offline = await safeStaticResponse(OFFLINE);
      await cache.put(OFFLINE, offline);
    } catch (_) { /* If offline shell was not fetched, install may still complete. */ }
    await Promise.allSettled([...STATIC].filter(path => path !== OFFLINE).map(async path => {
      const response = await safeStaticResponse(path);
      await cache.put(path, response);
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener("activate", event => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter(n => n.startsWith("bifrost-pwa-") && n !== CACHE_NAME)
      .map(n => caches.delete(n)));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", event => {
  const req = event.request;
  if (req.method !== "GET") return;       // Mutations can only go to the network.
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.startsWith("/api/") ||
      url.pathname.startsWith("/cdn-cgi/") ||
      url.pathname.startsWith("/auth/") ||
      url.pathname.startsWith("/oauth/")) return;
  if (req.mode === "navigate") {
    // No cached signed-in HTML, Node state, pairing fragments or session details.
    event.respondWith(fetch(req).catch(async () =>
      (await caches.match(OFFLINE)) ||
      new Response("BIFROST is offline. No Node status is available.",
        {status:503,headers:{"Content-Type":"text/plain; charset=utf-8"}})));
    return;
  }
  if (!STATIC.has(url.pathname) || url.search) return;
  event.respondWith((async () => {
    try {
      const response = await safeStaticResponse(url.pathname);
      const cache = await caches.open(CACHE_NAME);
      await cache.put(url.pathname, response.clone());
      return response;
    } catch (_) {
      return (await caches.match(url.pathname)) ||
        new Response("Static PWA resource unavailable.", {status:503});
    }
  })());
});
