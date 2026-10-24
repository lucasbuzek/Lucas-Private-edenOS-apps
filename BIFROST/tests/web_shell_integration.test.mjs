"use strict";
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import {fileURLToPath} from "node:url";

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "headless");
const html = fs.readFileSync(path.join(root,"index.html"),"utf8");
const script = fs.readFileSync(path.join(root,"dashboard.js"),"utf8");
const css = fs.readFileSync(path.join(root,"dashboard.css"),"utf8");
const begin = script.indexOf("/* BIFROST Web shell:");
const end = script.indexOf("/* Three different experiences over the SAME local authority.");
assert.ok(begin >= 0 && end > begin);
const shellScript = script.slice(begin,end);
class Element {
  constructor(tag="div"){
    this.tag=tag;this.children=[];this.attrs={};this.handlers={};
    this.dataset={};this.value="";this.textContent="";this.hidden=false;
    this.className="";this.scrolled=0;
  }
  append(...nodes){this.children.push(...nodes)}
  appendChild(n){this.children.push(n);return n}
  replaceChildren(...nodes){this.children=nodes}
  setAttribute(k,v){this.attrs[k]=v}
  addEventListener(type,cb){this.handlers[type]=cb}
  scrollIntoView(){this.scrolled++}
  click(){this.handlers.click?.({target:this})}
}
function harness(){
  const ids=[
    "webDock","webFavorites","webSpectrum","webSpectrumStatus","webAppView","webAppDetail","webBrowseCount",
    "homeHeadless","homeObservation","sideNodeStatus","homeConnections",
    "homeApps","webAttention","homeActivity","sidebarHome","sidebarApps",
    "sidebarConnections","sidebarMac","sidebarActivity","sidebarActions","sidebarSettings",
    "webConnectionsPanel","webConnectionTiles","webConnectionCount","webMacPanel",
    "webActivityPanel","webQuickActionsPanel",
    "webHome","webRefresh","webViewDetails","appSearch","sidebarNavMount","status","appBrowser",
    "kernel","orchestration","setups","webHomePanel","settingsPanel","experienceDescription"
  ];
  const elements=Object.fromEntries(ids.map(id=>[id,new Element()]));
  elements.kernel.dataset.minLevel="advanced";
  elements.orchestration.dataset.minLevel="advanced";
  elements.setups.dataset.minLevel="advanced";
  const layouts=["list","columns","gallery"].map(name=>{
    const e=new Element("button");e.dataset.appLayout=name;return e
  });
  const jumps=["appBrowser","kernel","orchestration"].map(name=>{
    const e=new Element("button");e.dataset.bifrostJump=name;return e
  });
  const nav = new Element("nav");
  const doc = {
    createElement:tag=>new Element(tag),
    querySelector:selector => selector === 'nav[aria-label="Dashboard shortcuts"]' ? nav : null,
    querySelectorAll:selector=>{
      if(selector==="[data-app-layout]")return layouts;
      if(selector==="[data-bifrost-jump]")return jumps;
      return [];
    }
  };
  let authorityRequests=0;
  const context={
    document:doc,$:id=>elements[id],
    levels:{simple:0,advanced:1,expert:2},
    setExperienceMode:()=>authorityRequests++,
    refresh:()=>{authorityRequests++},
  };
  vm.createContext(context);
  vm.runInContext(shellScript,context);
  const run=expr=>vm.runInContext(expr,context);
  return {run, elements, layouts, jumps, nav, authorityRequests:()=>authorityRequests};
}
test("web shell retains original authenticated dashboard screens and accessibility basics",()=>{
  for(const id of ["webHomePanel","homeHeadless","homeActivity","webDock",
                   "appBrowser","webAppView","webAppDetail","webFavorites","appSearch"]){
    assert.match(html,new RegExp('id="'+id+'"'));
  }
  for(const name of ["status","kernel","orchestration","diagnostics","activity","preferences"]){
    assert.match(html,new RegExp('id="'+name+'"'));
  }
  assert.match(css,/.web-shell/);
  assert.match(html,/aria-label="Application view"/);
  assert.doesNotMatch(shellScript,/localStorage|sessionStorage|eval\(|innerHTML\s*=|fetch\(|XMLHttpRequest|new Worker/);
});
test("Simple dock exposes BIFROST actions but unconnected specialist entries never acquire execution rights",()=>{
  const h=harness();
  assert.equal(h.elements.webDock.children.length,5);
  assert.equal(h.elements.webFavorites.children.length,5);
  assert.equal(h.run("shellApps.filter(a=>a.id!=='bifrost').every(a=>a.capabilities.length===0)"),true);
  assert.equal(h.run("shellNodeRunning"),false);
  assert.match(h.elements.homeHeadless.textContent, /^$/);
  h.run('shellUpdateStatus({headless:{status:"running",pid:1234}})');
  assert.equal(h.elements.homeHeadless.textContent,"Connected locally");
  assert.match(h.elements.homeApps.textContent,/BIFROST only/);
  assert.match(h.elements.webAppDetail.children.map(c=>c.textContent).join(" "),/Local service observed/);
  h.run("shellSelectApp('janitor')");
  assert.match(h.elements.webAppDetail.children.map(c=>c.textContent).join(" "),/Integration unverified/);
  assert.equal(h.run("shellSelectedApp"),"janitor");
});
test("Finder List Columns Gallery navigate the same catalog without fake connections",()=>{
  const h=harness();
  h.run('shellSetLayout("list")');
  assert.equal(h.layouts[0].attrs["aria-pressed"],"true");
  assert.ok(h.elements.webAppView.children.length>=2);
  h.run('shellSetLayout("columns")');
  assert.equal(h.elements.webAppView.children[0].className,"web-columns");
  assert.equal(h.layouts[1].attrs["aria-pressed"],"true");
  h.run('shellSetLayout("gallery")');
  assert.equal(h.elements.webAppView.children[0].className,"web-gallery");
  h.run('shellQuery="&<script>alert(1)</script>";shellRenderBrowser()');
  assert.match(h.elements.webAppView.children.map(c=>[c.textContent,...c.children.map(n=>n.textContent)].join(" ")).join(" "),/No matching/);
  assert.equal(h.authorityRequests(),0);
});
test("Offline invalidates last running state and previously shown receipts",()=>{
  const h=harness();
  h.run('shellUpdateStatus({headless:{status:"running",pid:2233}})');
  h.run('shellUpdateActivity(3)');
  assert.match(h.elements.homeActivity.textContent,/3 recent local/);
  h.run('shellMarkOffline()');
  assert.match(h.elements.homeHeadless.textContent,/Unknown/);
  assert.equal(h.elements.homeActivity.textContent,"Unavailable");
  assert.equal(h.run("shellNodeRunning"),false);
  assert.match(h.elements.webAppDetail.children.map(c=>c.textContent).join(" "),/Headless unavailable/);
});
test("Mode selection only changes presentation; no provider or account writes",()=>{
  const h=harness();
  h.run('shellApplyExperience("expert")');
  assert.equal(h.layouts[1].attrs["aria-pressed"],"true");
  h.run('shellApplyExperience("advanced")');
  assert.equal(h.layouts[0].attrs["aria-pressed"],"true");
  h.run('shellApplyExperience("simple")');
  assert.equal(h.layouts[2].attrs["aria-pressed"],"true");
  assert.equal(h.authorityRequests(),0);
});

test("Settings is one sidebar destination, not a duplicate toolbar popover or buried preferences",()=>{
  const h=harness();
  assert.equal((html.match(/id="sidebarSettings"/g)||[]).length,1);
  assert.equal((html.match(/id="settingsPanel"/g)||[]).length,1);
  assert.equal((html.match(/id="preferences"/g)||[]).length,1);
  assert.equal((html.match(/id="modeSimple"/g)||[]).length,1);
  assert.equal((html.match(/id="modeAdvanced"/g)||[]).length,1);
  assert.equal((html.match(/id="modeExpert"/g)||[]).length,1);
  assert.doesNotMatch(html,/id="experienceSettings"|class="web-settings-panel"|href="#preferences"/);
  assert.match(html,/id="settingsPanel" class="web-settings-page"/);
  assert.match(css,/\.web-settings-page/);
  assert.match(css,/\.web-settings-card/);
  assert.ok(h.elements.sidebarSettings.handlers.click);
  h.elements.sidebarSettings.click();
  assert.equal(h.elements.settingsPanel.scrolled,1);
  assert.equal(h.elements.sidebarSettings.attrs["aria-current"],"page");
  assert.equal(h.elements.sidebarHome.attrs["aria-current"],"false");
  // Advanced/Expert must remain an explicit, user-selected display choice.
  h.run('shellJump("kernel")');
  assert.equal(h.elements.kernel.scrolled,0);
  assert.equal(h.elements.settingsPanel.scrolled,2);
  assert.match(h.elements.experienceDescription.textContent,/requires advanced detail/);
  assert.equal(h.authorityRequests(),0);
  h.elements.sidebarHome.click();
  assert.equal(h.elements.sidebarHome.attrs["aria-current"],"page");
  assert.equal(h.elements.sidebarSettings.attrs["aria-current"],"false");
});

test("in-flight local activity may not repopulate receipts after session loss",async()=>{
  const fragment=script.slice(script.indexOf("async function loadLocalActivity()"),
                              script.indexOf("async function recordLocalCheck()"));
  assert.ok(fragment.includes("const sessionToken = token"));
  let resolveRequest;
  const target = new Element();
  const feedback = new Element();
  const refreshButton = new Element("button");
  const recordButton = new Element("button");
  let unknownCount=0;
  const context={
    token:"old-session",
    $:id=>({
      activityList:target,activityFeedback:feedback,activityRefresh:refreshButton,
      recordLocalCheck:recordButton
    })[id],
    shellActivityUnknown:()=>unknownCount++,
    shellUpdateActivity:()=>assert.fail("stale activity must not return"),
    fetch:()=>new Promise(resolve=>{resolveRequest=resolve}),
    document:{createElement:tag=>new Element(tag)}
  };
  vm.createContext(context);
  vm.runInContext(fragment,context);
  const pending=vm.runInContext("loadLocalActivity()",context);
  assert.equal(typeof resolveRequest,"function");
  context.token=null;
  resolveRequest({ok:true,json:async()=>({tasks:[{taskId:"stale",state:"complete"}]})});
  await pending;
  assert.equal(target.children.length,0);
  assert.equal(unknownCount,1);
});


test("spectral bridge paths mirror observed connections rather than implying all apps are online",()=>{
  const h=harness();
  assert.match(html,/id="webSpectrum"/);
  assert.match(html,/id="webSpectrumStatus"/);
  assert.match(css,/web-spectrum-path\[data-state="connected"\]/);
  assert.equal(h.elements.webSpectrum.children.length,5);
  assert.ok(h.elements.webSpectrum.children.every(item=>item.dataset.state==="unverified"));
  assert.equal(h.elements.webDock.children[0].tag,"button");
  assert.equal(h.elements.webDock.children[0].attrs.href,undefined);
  assert.equal(typeof h.elements.webDock.children[0].handlers.click,"function");
  h.run('shellUpdateStatus({headless:{status:"running",pid:456}})');
  assert.equal(h.elements.webSpectrum.children[0].dataset.state,"connected");
  assert.ok(h.elements.webSpectrum.children.slice(1).every(item=>item.dataset.state==="unverified"));
  assert.match(h.elements.webSpectrum.children[0].attrs["aria-label"],/BIFROST · Web connection verified/);
  assert.match(h.elements.webSpectrumStatus.textContent,/1 verified local Web UI/);
  assert.match(h.elements.homeConnections.textContent,/1 verified local Web UI/);
  h.run("shellMarkOffline()");
  assert.ok(h.elements.webSpectrum.children.every(item=>item.dataset.state==="unverified"));
  assert.match(h.elements.webSpectrumStatus.textContent,/0 verified local Web UIs/);
});

test("Apps Dock opens only verified same-origin Web UI in a new tab and never fabricates specialist URLs",()=>{
  const h=harness();
  h.run('shellUpdateStatus({headless:{status:"running",pid:321}})');
  assert.equal(h.run('shellWebDestination(shellApps[0])'),"/");
  assert.equal(h.run('shellApps.slice(1).every(app=>shellWebDestination(app)===null)'),true);
  const open=h.elements.webDock.children[0];
  assert.equal(open.tag,"a");
  assert.equal(open.attrs.href,"/");
  assert.equal(open.attrs.target,"_blank");
  assert.equal(open.attrs.rel,"noopener noreferrer");
  assert.match(open.attrs["aria-label"],/Open BIFROST Web UI/);
  assert.equal(h.elements.webFavorites.children[0].attrs.href,"/");
  for (const item of h.elements.webDock.children.slice(1)) {
    assert.equal(item.tag,"button");
    assert.equal(item.attrs.href,undefined);
    assert.equal(typeof item.handlers.click,"function");
    assert.match(item.attrs.title,/No verified Web UI URL/);
  }
  assert.equal(h.run("shellSelectedApp"),"bifrost");
  h.elements.webDock.children[1].click();
  assert.equal(h.run("shellSelectedApp"),"heimdall");
  assert.equal(h.authorityRequests(),0,"Inspecting an unconnected app must not execute an action");
  h.run('shellSelectApp("bifrost")');
  const verifiedLink=h.elements.webAppDetail.children.find(item=>item.className==="web-open-ui");
  assert.equal(verifiedLink?.attrs.href,"/");
  h.run('shellSelectApp("heimdall")');
  assert.ok(h.elements.webAppDetail.children.every(item=>item.className!=="web-open-ui"));
  assert.match(h.elements.webAppDetail.children.map(item=>item.textContent).join(" "),/No verified Web UI/);
  h.run("shellMarkOffline()");
  assert.ok(h.elements.webDock.children.every(item=>item.tag==="button" && !item.attrs.href));
  assert.ok(h.elements.webFavorites.children.every(item=>item.tag==="button" && !item.attrs.href));
  assert.doesNotMatch(shellScript,/window\.open\s*\(|eval\s*\(/);
  assert.doesNotMatch(shellScript,/https?:\/\/(?!127\.0\.0\.1:8787\/|127\.0\.0\.1:8765\/)/);
});

test("APPLE UX: Simple Advanced Expert live in Settings, not main navigation",()=>{
  const settings = html.indexOf('<section id="settingsPanel" class="web-settings-page"');
  const experience = html.indexOf('<div class="experience-switch"',settings);
  const settingsEnd = html.indexOf('</section>',settings);
  const hero = html.indexOf('<section id="webHomePanel"');
  const dock = html.indexOf('<div class="web-dock-panel"');
  const cards = html.indexOf('<div class="web-cards"');
  const appBrowser = html.indexOf('<section id="appBrowser"');
  const toolbar = html.indexOf('<div class="web-toolbar"');
  const nav = html.indexOf('<nav aria-label="Dashboard shortcuts">');
  assert.ok(settings > appBrowser && experience > settings && settingsEnd > experience);
  assert.ok(settings > nav, "detail selection lives in the same sidebar-linked Settings content as other screens");
  assert.ok(hero > 0 && dock > hero && dock < cards, "Dock is the first home action");
  assert.ok(toolbar > appBrowser, "Finder search/layout belongs with application browser");
  assert.match(html,/class="web-topbar"/);
  assert.match(html,/data-min-level="advanced" id="status"/);
  assert.match(html,/id="modeAdvanced"/);
  assert.match(css,/\.web-settings-card/);
  assert.match(css,/web-brand \.brand-symbol/);
  assert.match(css,/url\("\/icons\/icon-192\.png"\)/);
  assert.doesNotMatch(html.slice(nav,hero),/class="experience-switch"/);
});
test("APPLE UX: advanced action opens Settings, never silently elevates Simple",()=>{
  const h=harness();
  h.run('shellJump("kernel")');
  assert.equal(h.elements.kernel.scrolled,0);
  assert.equal(h.elements.settingsPanel.scrolled,1);
  assert.match(h.elements.experienceDescription.textContent,/requires advanced detail/);
  assert.equal(h.authorityRequests(),0);
  h.run('shellJump("appBrowser")');
  assert.equal(h.elements.appBrowser.scrolled,1);
  h.run('shellApplyExperience("advanced")');
  h.run('shellJump("kernel")');
  assert.equal(h.elements.kernel.scrolled,1);
  assert.equal(h.authorityRequests(),0);
});


test("ZERO Simple graphical sidebar has seven working destinations, including integrated Settings",()=>{
  const routes=[
    ["sidebarHome","webHomePanel"],
    ["sidebarConnections","webConnectionsPanel"],
    ["sidebarApps","appBrowser"],
    ["sidebarMac","webMacPanel"],
    ["sidebarActivity","webActivityPanel"],
    ["sidebarActions","webQuickActionsPanel"],
    ["sidebarSettings","settingsPanel"]
  ];
  assert.match(html,/aria-label="BIFROST workspace"/);
  assert.match(css,/\.web-side-icon-connections/);
  assert.match(css,/\.web-side-action\[aria-current="page"\]/);
  const h=harness();
  assert.equal(h.elements.sidebarHome.attrs["aria-current"],"page");
  for (const [id,section] of routes) {
    assert.match(html,new RegExp('id="'+id+'"'));
    assert.match(html,new RegExp('id="'+section+'"'));
    h.elements[id].click();
    assert.ok(h.elements[section].scrolled>0,id+" must navigate to a real section");
    assert.equal(h.elements[id].attrs["aria-current"],"page");
    for(const [other] of routes.filter(([other])=>other!==id)){
      assert.equal(h.elements[other].attrs["aria-current"],"false");
    }
  }
  assert.equal(h.authorityRequests(),0,"Simple navigation must not elevate authority");
});

test("ZERO sidebar Settings uses the existing navigation and one Settings page without changing permissions",()=>{
  const h=harness();
  const menu = html.slice(html.indexOf('<nav class="web-sidebar-actions"'),html.indexOf('</nav>'));
  assert.match(menu,/id="sidebarSettings"/);
  assert.doesNotMatch(html,/id="experienceSettings"/);
  h.elements.sidebarSettings.click();
  assert.equal(h.elements.settingsPanel.scrolled,1);
  assert.equal(h.elements.sidebarSettings.attrs["aria-current"],"page");
  assert.equal(h.authorityRequests(),0);
  h.run('shellJump("kernel")');
  assert.equal(h.elements.kernel.scrolled,0);
  assert.equal(h.elements.settingsPanel.scrolled,2);
  assert.equal(h.authorityRequests(),0);
});

test("ZERO graphical connection board shows only verified Web paths and invalidates on loss",()=>{
  const h=harness();
  assert.match(html,/id="webConnectionsPanel"/);
  assert.match(html,/id="webConnectionTiles"/);
  assert.match(css,/web-connection-tile\[data-state="connected"\]/);
  assert.equal(h.elements.webConnectionTiles.children.length,5);
  assert.ok(h.elements.webConnectionTiles.children.every(t=>t.dataset.state==="unverified"));
  assert.match(h.elements.webConnectionCount.textContent,/0 of 5 Web connections verified/);
  h.run('shellUpdateStatus({headless:{status:"running",pid:1234}})');
  assert.equal(h.elements.webConnectionTiles.children[0].dataset.state,"connected");
  assert.ok(h.elements.webConnectionTiles.children.slice(1).every(t=>t.dataset.state==="unverified"));
  assert.match(h.elements.webConnectionCount.textContent,/1 of 5 Web connections verified/);
  assert.equal(h.elements.webDock.children[0].attrs.href,"/");
  assert.ok(h.elements.webDock.children.slice(1).every(t=>
    !t.attrs.href && typeof t.handlers.click === "function"));
  assert.equal(h.authorityRequests(),0);
  h.run("shellMarkOffline()");
  assert.ok(h.elements.webConnectionTiles.children.every(t=>t.dataset.state==="unverified"));
  assert.match(h.elements.webConnectionCount.textContent,/0 of 5 Web connections verified/);
  assert.equal(h.authorityRequests(),0);
});

test("only fresh identity-verified HEIMDALL and PENELOPE Web UIs gain actual Dock links",()=>{
  const h=harness();
  h.run('shellUpdateStatus({headless:{status:"running",pid:321}})');
  h.run('globalThis.token="synthetic-private-session"');
  h.run('globalThis.window={BifrostConnections:{apps:['+
        '{id:"heimdall",webVerified:true,webURL:"http://127.0.0.1:8787/"},'+
        '{id:"penelope",webVerified:true,webURL:"http://127.0.0.1:8765/"},'+
        '{id:"janitor",webVerified:true,webURL:"http://127.0.0.1:9999/"}'+
      ']}}');
  h.run("shellRenderDock()");
  const heimdall=h.elements.webDock.children[1];
  const penelope=h.elements.webDock.children[3];
  assert.equal(heimdall.tag,"a");
  assert.equal(heimdall.attrs.href,"http://127.0.0.1:8787/");
  assert.equal(heimdall.attrs.target,"_blank");
  assert.equal(heimdall.attrs.rel,"noopener noreferrer");
  assert.equal(penelope.tag,"a");
  assert.equal(penelope.attrs.href,"http://127.0.0.1:8765/");
  assert.equal(h.elements.webDock.children[2].tag,"button");
  assert.equal(h.elements.webDock.children[4].tag,"button");
  assert.equal(h.elements.webSpectrum.children.filter(x=>x.dataset.state==="connected").length,3);
  // Route mounting is outside this isolated shell slice; inspect the panel
  // directly instead of invoking the unrelated navigation router.
  h.run('shellSelectedApp="heimdall";shellRenderBrowser()');
  const link=h.elements.webAppDetail.children.find(x=>x.className==="web-open-ui");
  assert.equal(link?.attrs.href,"http://127.0.0.1:8787/");
  // A wrong origin, an unverified URL, or missing local authorization must
  // remove the anchor immediately. The record remains inspectable only.
  h.run('window.BifrostConnections.apps[0].webURL="http://127.0.0.1:7878/";shellRenderDock()');
  assert.equal(h.elements.webDock.children[1].tag,"button");
  h.run('window.BifrostConnections.apps[1].webVerified=false;shellRenderDock()');
  assert.equal(h.elements.webDock.children[3].tag,"button");
  h.run('token=null;shellRenderDock()');
  assert.ok(h.elements.webDock.children.slice(1).every(x=>x.tag==="button"));
  assert.equal(h.authorityRequests(),0);
});
