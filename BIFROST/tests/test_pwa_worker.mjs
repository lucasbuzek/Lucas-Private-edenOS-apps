import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";
import vm from "node:vm";
import test from "node:test";

const folder=path.dirname(fileURLToPath(import.meta.url));
const local=path.resolve(folder,"../headless/sw.js");
const file=local;
const source=readFileSync(file,"utf8");

function workerEnvironment(origin="http://127.0.0.1:8798") {
  const handlers={};
  let online=true;
  const cacheContents=new Map();
  const cacheSets=new Map();
  const putLog=[];
  const response=(url)=>({
    ok:true,url:new URL(url,origin).href,status:200,redirected:false,
    headers:{get(name) {
      if(name.toLowerCase()!=="content-type")return null;
      const p=new URL(url,origin).pathname;
      if(p.endsWith(".png"))return "image/png";
      if(p.endsWith(".js"))return "text/javascript";
      if(p.endsWith(".css"))return "text/css";
      if(p.endsWith(".webmanifest"))return "application/manifest+json";
      return "text/html; charset=utf-8";
    }},
    clone(){return {...this};},tag:new URL(url,origin).pathname
  });
  const caches={
    open:async (name)=>{if(!cacheSets.has(name))cacheSets.set(name,true);return {
      put:async (url,res)=>{putLog.push(url);cacheContents.set(url,res);},
      match:async (url)=>cacheContents.get(url),
    }},
    match:async (url)=>cacheContents.get(url),
    keys:async ()=>[...cacheSets.keys()],
    delete:async name=>{cacheSets.delete(name);return true}
  };
  const self={
    location:new URL(origin),
    addEventListener:(type,callback)=>handlers[type]=callback,
    skipWaiting:async()=>{},
    clients:{claim:async()=>{}}
  };
  const fakeFetch=async url=>{
    if(!online)throw Error("network unavailable");
    return response(typeof url==="string"?url:url.url);
  };
  const context={
    self,caches,fetch:fakeFetch,URL,Set,Response,Promise,Error,
    console,
  };
  vm.runInNewContext(source,context,{filename:file});
  async function dispatch(type,request) {
    let waited,responded;
    const event={
      request,
      waitUntil:promise=>{waited=promise;},
      respondWith:promise=>{responded=promise;},
    };
    handlers[type](event);
    if(waited) await waited;
    return responded?await responded:undefined;
  }
  return {dispatch,setOnline:value=>{online=value;},cacheContents,putLog,response};
}

test("PWA service worker caches static assets only",async()=>{
  const world=workerEnvironment();
  await world.dispatch("install");
  assert.ok(world.putLog.includes("/offline.html"));
  assert.ok(world.putLog.includes("/manifest.webmanifest"));
  assert.ok(world.putLog.includes("/icons/icon-192.png"));
  assert.ok(!world.putLog.some(path=>path.includes("/api/")));
});

test("PWA intercept is absent for all API, auth and write requests",async()=>{
  const world=workerEnvironment();
  await world.dispatch("install");
  for(const target of ["/api/state","/api/session","/api/setup/stage",
                       "/api/pwa/adapter","/cdn-cgi/access/login","/auth/callback"]) {
    const result=await world.dispatch("fetch",{
      method:"GET",mode:"cors",url:"http://127.0.0.1:8798"+target
    });
    assert.equal(result,undefined,target);
  }
  assert.equal(await world.dispatch("fetch",{
    method:"POST",mode:"cors",url:"http://127.0.0.1:8798/api/control"
  }),undefined);
  assert.equal(await world.dispatch("fetch",{
    method:"GET",mode:"cors",url:"https://different-origin.test/api/state"
  }),undefined);
});

test("network-first navigation is never stored and offline shows anonymous fallback",async()=>{
  const world=workerEnvironment();
  await world.dispatch("install");
  const navigation={method:"GET",mode:"navigate",url:"http://127.0.0.1:8798/"};
  const html=await world.dispatch("fetch",navigation);
  assert.equal(html.url,navigation.url);
  assert.ok(!world.putLog.includes("/"));
  world.setOnline(false);
  const offline=await world.dispatch("fetch",navigation);
  assert.equal(offline.tag,"/offline.html");
  assert.ok(!world.putLog.some(p=>p.includes("/api")||p==="/"));
});

test("static assets can load offline; no unknown resource cached",async()=>{
  const world=workerEnvironment();
  await world.dispatch("install");
  world.setOnline(false);
  const icon=await world.dispatch("fetch",{
    method:"GET",mode:"cors",url:"http://127.0.0.1:8798/icons/icon-512.png"
  });
  assert.equal(icon.tag,"/icons/icon-512.png");
  const unexpected=await world.dispatch("fetch",{
    method:"GET",mode:"cors",url:"http://127.0.0.1:8798/private-notes.json"
  });
  assert.equal(unexpected,undefined);
});
