"use strict";
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import {fileURLToPath} from "node:url";

const headless=path.join(path.dirname(fileURLToPath(import.meta.url)),"..","headless");
const js=fs.readFileSync(path.join(headless,"dashboard.js"),"utf8");
const css=fs.readFileSync(path.join(headless,"dashboard.css"),"utf8");
const html=fs.readFileSync(path.join(headless,"index.html"),"utf8");
const start=js.indexOf("/* BIFROST subpage routing (APPLE UX");
assert.ok(start>0,"new routing must extend existing authorized shell");
const router=js.slice(start);

class Element {
  constructor(tag="section"){
    this.tag=tag;this.attrs={};this.dataset={};this.handlers={};this.hidden=false;
    this.children=[];this.textContent="";
  }
  setAttribute(name,value){this.attrs[name]=String(value)}
  removeAttribute(name){delete this.attrs[name]}
  getAttribute(name){return this.attrs[name]}
  addEventListener(name,callback){this.handlers[name]=callback}
  append(...items){this.children.push(...items)}
}
function harness(initialHash=""){
  const pageIds=["webHomePanel","appBrowser","settingsPanel","status","orchestration",
    "activity","interconnect","kernel","setups","diagnostics"];
  const extra=["experienceDescription","sidebarMenuToggle"];
  const elements=Object.fromEntries([...pageIds,...extra].map(id=>[id,new Element()]));
  const content=new Element("main"), sidebar=new Element("aside"),brand=new Element("header"),
    heading=new Element("span"),nav=new Element("nav");
  const links=["status","interconnect","orchestration","kernel","setups","diagnostics"].map(id=>{
    const anchor=new Element("a");anchor.setAttribute("href","#"+id);return anchor;
  });
  nav.querySelectorAll=()=>links;
  const selectors={
    ".web-content":content,".web-sidebar":sidebar,
    ".web-brand":brand,
    ".web-topbar-identity .sub":heading,
    'nav[aria-label="Dashboard shortcuts"]':nav
  };
  const eventHandlers={};
  let selected=null,scrollCount=0,toolJump=null;
  let mode="simple";
  const win={
    location:{hash:initialHash},
    addEventListener:(name,callback)=>{eventHandlers[name]=callback},
    scrollTo:()=>{scrollCount++}
  };
  const doc={
    title:"BIFROST",
    createElement:tag=>new Element(tag),
    querySelector:selector=>selectors[selector]||null
  };
  const context={
    window:win,document:doc,$:id=>id==="sidebarMenuToggle"
      ? (brand.children.find(item=>item.id===id)||null) : (elements[id]||null),
    levels:{simple:0,advanced:1,expert:2},
    shellMode:mode,
    shellMarkSidebar:target=>{selected=target},
    shellJump:id=>{toolJump=id}
  };
  vm.createContext(context);
  vm.runInContext(router,context);
  const run=expr=>vm.runInContext(expr,context);
  return {
    run,elements,content,sidebar,brand,heading,nav,links,doc,win,
    select:()=>selected,scrolls:()=>scrollCount,toolJump:()=>toolJump,
    setMode:value=>{context.shellMode=value},
    back:hash=>{win.location.hash=hash;eventHandlers.hashchange()}
  };
}

test("BIFROST uses seven consistent sidebar subpages and existing advanced destinations",()=>{
  const h=harness();
  assert.equal(h.content.dataset.bifrostPage,"home");
  assert.equal(h.select(),"webHomePanel");
  assert.equal(h.heading.textContent,"Home");
  assert.equal(h.elements.webHomePanel.hidden,false);
  assert.equal(h.elements.appBrowser.hidden,true);
  for(const [route,sidebar] of [
    ["connections","webConnectionsPanel"],["apps","appBrowser"],
    ["mac","webMacPanel"],["activity","webActivityPanel"],
    ["actions","webQuickActionsPanel"],["settings","settingsPanel"]]){
    h.run('shellNavigatePage("'+route+'")');
    assert.equal(h.content.dataset.bifrostPage,route);
    assert.equal(h.select(),sidebar);
    assert.equal(h.win.location.hash,"#/"+route);
    assert.equal(h.doc.title,"BIFROST · "+h.heading.textContent);
  }
  assert.match(html,/id="sidebarSettings"/);
  assert.match(html,/id="settingsPanel"/);
  assert.match(html,/id="sidebarConnections"/);
  assert.match(html,/id="webConnectionsPanel"/);
  assert.match(css,/data-bifrost-page="connections"/);
  assert.match(css,/data-bifrost-page="actions"/);
});

test("only the selected main region is shown for each subpage",()=>{
  const h=harness();
  const ids=["webHomePanel","appBrowser","settingsPanel","status","orchestration",
    "activity","interconnect","kernel","setups","diagnostics"];
  for(const [page,visible] of [["home","webHomePanel"],["connections","webHomePanel"],
    ["actions","webHomePanel"],["apps","appBrowser"],["mac","status"],
    ["activity","activity"],["settings","settingsPanel"]]){
    h.run('shellNavigatePage("'+page+'")');
    assert.deepEqual(ids.filter(id=>!h.elements[id].hidden),[visible],page);
  }
  assert.match(css,/data-bifrost-page="home".*#webConnectionsPanel/);
  assert.match(css,/data-bifrost-page="home".*#webQuickActionsPanel/);
});

test("browser history and direct deep links restore the correct page",()=>{
  const h=harness("#/activity");
  assert.equal(h.content.dataset.bifrostPage,"activity");
  h.run('shellNavigatePage("apps")');
  assert.equal(h.win.location.hash,"#/apps");
  h.back("#/connections");
  assert.equal(h.heading.textContent,"Connections");
  h.back("#/settings");
  assert.equal(h.elements.settingsPanel.hidden,false);
  h.back("#kernel");
  assert.equal(h.content.dataset.bifrostPage,"settings");
  assert.match(h.elements.experienceDescription.textContent,/requires advanced detail/);
});

test("Advanced and Expert pages do not silently elevate permissions or mode",()=>{
  const h=harness();
  h.run('shellNavigatePage("diagnostics")');
  assert.equal(h.content.dataset.bifrostPage,"settings");
  assert.equal(h.elements.diagnostics.hidden,true);
  assert.match(h.elements.experienceDescription.textContent,/requires expert detail/);
  h.setMode("advanced");
  h.run('shellNavigatePage("orchestration")');
  assert.equal(h.content.dataset.bifrostPage,"orchestration");
  h.run('shellNavigatePage("diagnostics")');
  assert.equal(h.content.dataset.bifrostPage,"settings");
  h.setMode("expert");
  h.run('shellNavigatePage("diagnostics")');
  assert.equal(h.content.dataset.bifrostPage,"diagnostics");
  assert.equal(h.elements.diagnostics.hidden,false);
  assert.doesNotMatch(router,/fetch\(|localStorage|sessionStorage|XMLHttpRequest|eval\(/);
});

test("mobile BIFROST menu is one accessible control under brand",()=>{
  const h=harness();
  assert.equal(h.brand.children.length,1);
  const toggle=h.brand.children[0];
  assert.equal(toggle.attrs["aria-expanded"],"false");
  assert.equal(h.sidebar.dataset.menuOpen,"false");
  toggle.handlers.click();
  assert.equal(toggle.attrs["aria-expanded"],"true");
  assert.equal(h.sidebar.dataset.menuOpen,"true");
  h.run('shellNavigatePage("mac")');
  assert.equal(h.sidebar.dataset.menuOpen,"false");
  assert.equal(toggle.attrs["aria-expanded"],"false");
  assert.match(css,/web-sidebar\[data-menu-open="false"\]/);
  assert.match(css,/\.web-nav-toggle:focus-visible/);
});

test("sidebar tools use the same page navigation instead of naked scrolling",()=>{
  const h=harness();
  const first=h.links[0];
  let prevented=false;
  h.nav.handlers.click({target:{closest:()=>first},preventDefault:()=>{prevented=true}});
  assert.equal(prevented,true);
  assert.equal(h.toolJump(),"status");
  assert.equal(h.select(),"webHomePanel");
});

test("invalid or external fragment never becomes an arbitrary destination",()=>{
  const h=harness("#/https://evil.example");
  assert.equal(h.content.dataset.bifrostPage,"home");
  assert.equal(h.elements.webHomePanel.hidden,false);
  assert.equal(h.doc.title,"BIFROST · Home");
  assert.doesNotMatch(router,/window\.open\s*\(/);
  assert.doesNotMatch(router,/http:\/\/|https:\/\//);
});
