"use strict";
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import {fileURLToPath} from "node:url";

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "headless");
const js = fs.readFileSync(path.join(root, "connection_fabric.js"), "utf8");
const html = fs.readFileSync(path.join(root, "index.html"), "utf8");

function fixture(){
  return {
    schema:"bifrost.connections.observation.v1",
    thisDevice:{name:"Mac-test",type:"this-mac",state:"local-session-observed"},
    lan:{interface:"en0",address:"192.168.8.254",subnet:"192.168.8.0/24",
         observedPeers:[],scan:{status:"not-scanned",scanned:0,total:0,responders:[]}},
    rdc:{selected:"RDC6"},
    apps:[],
    connectors:[],
  };
}
class Element {
  constructor(tag="div"){
    this.tag=tag;this.children=[];this.handlers={};this.attrs={};this.dataset={};
    this.disabled=false;this.textContent="";this.value="";this.style={setProperty(){},top:""};
  }
  append(...parts){this.children.push(...parts)}
  replaceChildren(...parts){this.children=parts}
  setAttribute(key,value){this.attrs[key]=value}
  addEventListener(name,fn){this.handlers[name]=fn}
  click(){this.handlers.click?.()}
}
function harness(allow=true){
  const elements=new Map();
  const el=id => {
    if(!elements.has(id))elements.set(id,new Element());
    return elements.get(id);
  };
  el("connectionRangeStart").value="1";
  el("connectionRangeEnd").value="32";
  el("connectionMonitorInterval").value="30";
  const docHandlers={}, winHandlers={}, timers=new Map(), calls=[];
  let nextTimer=1;
  const document={
    hidden:false,getElementById:el,createElement:tag=>new Element(tag),
    addEventListener:(name,fn)=>{docHandlers[name]=fn},
  };
  const window={
    confirm:()=>allow,
    addEventListener:(name,fn)=>{winHandlers[name]=fn},
  };
  const context={
    window,document,token:"private-synthetic-session",
    setInterval:(fn,delay)=>{const id=nextTimer++;timers.set(id,{fn,delay});return id;},
    clearInterval:id=>timers.delete(id),
    fetch:async (url,options)=>{
      calls.push({url,options});
      if(url==="/api/connections/v1")
        return {ok:true,status:200,json:async()=>fixture()};
      if(url==="/api/connections/scan"){
        const body=JSON.parse(options.body);
        assert.equal(options.method,"POST");
        assert.equal(options.headers["X-Bifrost-Token"],"private-synthetic-session");
        assert.equal(body.confirmed,true);
        assert.ok(body.start>=1 && body.end<=254 && body.end-body.start<64);
        return {ok:true,status:202,json:async()=>({scan:{status:"scanning"}})};
      }
      throw Error("Unexpected source: "+url);
    }
  };
  vm.createContext(context);
  vm.runInContext(js,context);
  docHandlers.DOMContentLoaded();
  return {
    el,document,window,context,calls,timers,
    tick:delay=>{
      for(const {fn,delay:d} of [...timers.values()])
        if(d===delay)fn();
    },
    monitorTick:()=>{
      const match=[...timers.values()].find(x=>x.fn.name==="monitorTick");
      assert.ok(match,"explicit monitor timer must be installed");
      match.fn();
    },
    pagehide:()=>winHandlers.pagehide(),
    visibilityChange:()=>docHandlers.visibilitychange(),
  };
}
const flush=async()=>{await new Promise(resolve=>setImmediate(resolve));await new Promise(resolve=>setImmediate(resolve));};
async function loaded(h){
  h.tick(450);await flush();
  assert.ok(h.calls.some(x=>x.url==="/api/connections/v1"));
}
const probes=h=>h.calls.filter(x=>x.url==="/api/connections/scan").length;

test("monitor control is a user-facing, disabled-by-default owner choice",()=>{
  assert.match(html,/id="connectionMonitorToggle" aria-pressed="false" disabled/);
  assert.match(js,/window\.confirm\("Monitor "/);
  assert.match(js,/document\.addEventListener\("visibilitychange"/);
  assert.doesNotMatch(js,/localStorage|sessionStorage|eval\(|innerHTML\s*=/);
});

test("load and routine refresh never probe a LAN before opt-in",async()=>{
  const h=harness();
  await loaded(h);
  h.tick(30000);await flush();
  assert.equal(probes(h),0);
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],undefined);
});

test("declining monitoring consent cannot start probing",async()=>{
  const h=harness(false);await loaded(h);
  h.el("connectionMonitorToggle").click();await flush();
  assert.equal(probes(h),0);
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],undefined);
});

test("one confirmed scoped range enables repeat probes and explicit Stop",async()=>{
  const h=harness(true);await loaded(h);
  h.el("connectionMonitorToggle").click();await flush();
  assert.equal(probes(h),1);
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],"true");
  assert.match(h.el("connectionMonitorToggle").textContent,/Stop/);
  const active=[...h.timers.values()].find(x=>x.fn.name==="monitorTick");
  assert.ok(active);assert.equal(active.delay,30000);
  h.monitorTick();await flush();
  assert.equal(probes(h),2);
  h.el("connectionMonitorToggle").click();
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],"false");
  active.fn();await flush();
  assert.equal(probes(h),2);
});

test("invalid range is rejected before consent, not silently widened",async()=>{
  const h=harness();await loaded(h);
  h.el("connectionRangeEnd").value="65";
  h.el("connectionMonitorToggle").click();await flush();
  assert.equal(probes(h),0);
  assert.match(h.el("connectionScanState").textContent,/1–64/);
});

test("changing network selection revokes monitoring permission",async()=>{
  const h=harness();await loaded(h);
  h.el("connectionMonitorToggle").click();await flush();
  assert.equal(probes(h),1);
  h.el("connectionRangeEnd").value="5";
  h.el("connectionRangeEnd").handlers.change();
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],"false");
  assert.equal([...h.timers.values()].filter(x=>x.fn.name==="monitorTick").length,0);
});

test("session rotation, tab visibility and pagehide stop scans",async()=>{
  const h=harness();await loaded(h);
  h.el("connectionMonitorToggle").click();await flush();
  const initial=probes(h);
  h.context.token="new-session";
  h.monitorTick();await flush();
  assert.equal(probes(h),initial);
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],"false");

  h.context.token="private-synthetic-session";
  h.el("connectionMonitorToggle").click();await flush();
  h.document.hidden=true;
  h.visibilityChange();
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],"false");
  h.document.hidden=false;
  h.el("connectionMonitorToggle").click();await flush();
  h.pagehide();
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],"false");
  assert.equal([...h.timers.values()].length,0);
});

test("interval change requires fresh owner consent",async()=>{
  const h=harness();await loaded(h);
  h.el("connectionMonitorToggle").click();await flush();
  h.el("connectionMonitorInterval").value="60";
  h.el("connectionMonitorInterval").handlers.change();
  assert.equal(h.el("connectionMonitorToggle").attrs["aria-pressed"],"false");
  assert.equal([...h.timers.values()].filter(x=>x.fn.name==="monitorTick").length,0);
});
