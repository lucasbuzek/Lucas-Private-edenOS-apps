"use strict";
import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";
import { fileURLToPath } from "node:url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));

const root = path.join(__dirname, "..", "headless");
const html = fs.readFileSync(path.join(root, "index.html"), "utf8");
const source = fs.readFileSync(path.join(root, "dashboard.js"), "utf8");
const uxSource = source.slice(source.indexOf("/* Three different experiences"));
test("three web workspaces have distinct task and diagnostic content", () => {
  for (const mode of ["Simple","Advanced","Expert"]) {
    assert.match(html, new RegExp('id="mode' + mode + '"'));
  }
  assert.match(html, /id="status"/);
  assert.match(html, /data-min-level="advanced" id="orchestration"/);
  assert.match(html, /data-min-level="advanced" id="kernel"/);
  assert.match(html, /data-min-level="expert" id="diagnostics"/);
  assert.match(html, /id="expertSource"/);
});
test("mode selection changes actual content and navigation, without granting permissions", () => {
  const elements = [
    {dataset:{minLevel:"advanced"},hidden:false},
    {dataset:{minLevel:"expert"},hidden:false},
    {dataset:{minLevel:"advanced"},hidden:false},
  ];
  const buttons={};
  for (const mode of ["Simple","Advanced","Expert"]) {
    const button={
      attrs:{}, selected:false,
      setAttribute(k,v){this.attrs[k]=v;},
      classList:{toggle(_class,value){button.selected=value;}},
      addEventListener(_event,callback){button.run=callback;}
    };
    buttons["mode"+mode]=button;
  }
  buttons.diagnosticsRefresh={addEventListener(){}};
  const message={textContent:""};
  const context={
    token:null,
    $:id => id==="experienceDescription" ? message : buttons[id],
    document:{querySelectorAll: selector => selector==="[data-min-level]" ? elements:[]},
    fetch:()=>{throw Error("No network request permitted by this test")},
  };
  vm.runInNewContext(uxSource,context);
  assert.equal(elements[0].hidden,true,"Simple conceals Advanced workflows");
  assert.equal(elements[1].hidden,true,"Simple conceals Expert evidence");
  assert.equal(buttons.modeSimple.attrs["aria-pressed"],"true");
  buttons.modeAdvanced.run();
  assert.equal(elements[0].hidden,false);
  assert.equal(elements[1].hidden,true);
  assert.equal(buttons.modeAdvanced.attrs["aria-pressed"],"true");
  buttons.modeExpert.run();
  assert.equal(elements[0].hidden,false);
  assert.equal(elements[1].hidden,false);
  assert.equal(buttons.modeExpert.attrs["aria-pressed"],"true");
  assert.match(message.textContent,/No extra execution authority/);
});
test("expert UI only reads public local health and never submits scripts", () => {
  assert.match(uxSource, /fetch\("\/api\/health"/);
  assert.doesNotMatch(uxSource,/\/api\/orchestration\/v1/);
  assert.doesNotMatch(uxSource,/workflow\.run/);
  assert.doesNotMatch(uxSource,/localStorage|sessionStorage/);
});

