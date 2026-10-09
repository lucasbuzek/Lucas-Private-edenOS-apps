// BIFROST service-worker security regression, no browser or network needed.
// Run node --test tests/pwa_sw.test.mjs; choose optional BIFROST_SW_UNDER_TEST
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";
import {fileURLToPath} from "node:url";

const SW = process.env.BIFROST_SW_UNDER_TEST || fileURLToPath(new URL("../public/sw.js", import.meta.url));

function response(path, body = "public", opts = {}) {
  const type = opts.type || (
    path.endsWith(".png") ? "image/png" :
    path.endsWith(".css") ? "text/css" :
    path.endsWith(".js") ? "text/javascript" :
    path.endsWith(".webmanifest") ? "application/manifest+json" : "text/html");
  const result = new Response(body, {status: 200, headers: {"Content-Type": type}});
  Object.defineProperty(result, "url", {value: opts.url || "https://bifrost.test" + path});
  Object.defineProperty(result, "redirected", {value: !!opts.redirected});
  return result;
}

function mockWorld(overrides = {}) {
  const events = new Map();
  const all = new Map();
  const fetches = [];
  let network = overrides.network || (async req => {
    const path = typeof req === "string" ? req : new URL(req.url).pathname;
    return response(path, path === "/offline.html" ? "BIFROST offline; live actions unavailable." : "public");
  });
  const self = {
    location: {origin: "https://bifrost.test"},
    clients: {claim: async () => {}},
    skipWaiting: async () => {},
    addEventListener(type, fn) { events.set(type, fn); }
  };
  const caches = {
    async open(name) {
      if (!all.has(name)) all.set(name, new Map());
      const map = all.get(name);
      return {
        async put(path, result) {map.set(path, result.clone());},
        async match(path) {return map.get(path);}
      };
    },
    async match(path) {
      for (const map of all.values()) if (map.has(path)) return map.get(path);
      return undefined;
    },
    async keys() {return [...all.keys()];},
    async delete(name) {return all.delete(name);}
  };
  const context = vm.createContext({
    self, caches, URL, Response, Set, Promise,
    fetch: async (request, options) => {
      fetches.push([request, options]);
      return network(request, options);
    },
  });
  vm.runInContext(fs.readFileSync(SW, "utf8"), context, {filename: SW});

  async function lifecycle(type) {
    let promise;
    events.get(type)({waitUntil(p) {promise = p;}});
    if (!promise) throw Error(type + " missing waitUntil");
    await promise;
  }
  async function intercepted(path, options = {}) {
    let handled = false;
    let promise;
    const event = {
      request: {
        method: options.method || "GET",
        mode: options.mode || "cors",
        url: options.url || "https://bifrost.test" + path,
      },
      respondWith(p) {handled = true;promise = p;}
    };
    events.get("fetch")(event);
    return {handled, answer: handled ? await promise : undefined};
  }
  return {all, caches, fetches, lifecycle, intercepted, setNetwork(fn) {network = fn;}};
}

test("PWA static assets cache only expected public MIME types", async () => {
  const w = mockWorld();
  await w.lifecycle("install");
  const list = [...w.all.values()].flatMap(cache => [...cache.keys()]);
  assert(list.includes("/offline.html"));
  assert(list.some(path => path.endsWith(".webmanifest")));
  assert(list.some(path => path.endsWith(".png")));
  assert(!list.some(path => path.startsWith("/api/")));
  assert(!list.some(path => path.startsWith("/auth/")));
  assert(!list.some(path => path.startsWith("/cdn-cgi/")));
});

test("authenticated APIs, mutating methods and third-party requests never intercepted", async () => {
  const w = mockWorld();
  for (const route of ["/api/state", "/api/session", "/api/setup/stage", "/api/actions", "/auth/callback", "/cdn-cgi/access/logout", "/oauth/start"]) {
    assert.equal((await w.intercepted(route)).handled, false, route);
  }
  for (const method of ["POST", "PUT", "PATCH", "DELETE"]) {
    assert.equal((await w.intercepted("/dashboard.css", {method})).handled, false);
  }
  assert.equal((await w.intercepted("/", {url:"https://external.test/"})).handled, false);
});

test("navigation offline fallback cannot replay previously authenticated app state", async () => {
  const w = mockWorld();
  await w.lifecycle("install");
  w.setNetwork(async () => {throw new Error("network unavailable");});
  const outcome = await w.intercepted("/", {mode:"navigate"});
  assert.equal(outcome.handled, true);
  assert(outcome.answer);
  const html = await outcome.answer.text();
  assert(html.toLowerCase().includes("offline"));
  assert(![...w.all.values()].some(cache => cache.has("/")));
});

test("same-origin redirects cannot populate the static shell cache", async () => {
  const w = mockWorld({
    network: async path => response(path, "<html>login</html>", {type:"text/html", redirected:true})
  });
  await w.lifecycle("install");
  const entries = [...w.all.values()].flatMap(cache=>[...cache.keys()]);
  assert.equal(entries.length, 0);
});

test("unexpected HTML instead of JavaScript never enters static cache", async () => {
  const w = mockWorld();
  await w.lifecycle("install");
  const candidates = [...w.all.values()].flatMap(map=>[...map.keys()]).filter(k=>k.endsWith(".js"));
  assert(candidates.length > 0);
  const path = candidates[0];
  w.setNetwork(async () => response(path, "LOGIN", {type:"text/html", redirected:true}));
  const out = await w.intercepted(path);
  assert(out.handled);
  assert.notEqual(await out.answer.text(), "LOGIN");
});

test("service-worker cache names can be replaced without changing API behavior", async () => {
  const w = mockWorld();
  await w.caches.open("bifrost-pwa-old-uncached");
  await w.lifecycle("install");
  await w.lifecycle("activate");
  assert(![...w.all.keys()].includes("bifrost-pwa-old-uncached"));
  assert((await w.intercepted("/api/state")).handled === false);
});
