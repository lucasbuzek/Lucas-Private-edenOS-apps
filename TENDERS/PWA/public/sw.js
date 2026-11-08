// Standalone or subpath-scoped offline shell. Never intercept another RAVEN application.
const CACHE_PREFIX="tenders-shell-";
const CACHE=CACHE_PREFIX+"v4";
const ROOT=new URL(self.registration.scope);
const SHELL=["","index.html","manifest.webmanifest","icons/tenders.svg","icons/tenders-180.png","icons/tenders-192.png","icons/tenders-512.png"].map(x=>new URL(x,ROOT).href);
self.addEventListener("install",event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(SHELL)).then(()=>self.skipWaiting())));
self.addEventListener("activate",event=>event.waitUntil(Promise.all([
 caches.keys().then(keys=>Promise.all(keys.filter(key=>key.startsWith(CACHE_PREFIX)&&key!==CACHE).map(key=>caches.delete(key)))),
 self.clients.claim()
])));
self.addEventListener("fetch",event=>{
 const request=event.request,url=new URL(request.url);
 if(request.method!=="GET"||url.origin!==ROOT.origin)return;
 const staticAsset=SHELL.includes(url.href)||url.pathname.startsWith(ROOT.pathname+"assets/");
 // Never cache private APIs, authenticated records, login results, or other apps' responses.
 if(!staticAsset)return;
 event.respondWith((async()=>{
  const cache=await caches.open(CACHE);
  try{
   const response=await fetch(request);
   if(response.ok&&response.type==="basic")await cache.put(request,response.clone());
   return response;
  }catch{
   const hit=await cache.match(request);
   if(hit)return hit;
   if(request.mode==="navigate")return await cache.match(new URL("index.html",ROOT).href)||Response.error();
   return Response.error();
  }
 })());
});
