import test from "node:test";
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";

const html = readFileSync(new URL("../headless/index.html", import.meta.url), "utf8");
const js = readFileSync(new URL("../headless/dashboard.js", import.meta.url), "utf8");
const sw = readFileSync(new URL("../headless/sw.js", import.meta.url), "utf8");

test("local PWA has explicit user-driven receipt controls", () => {
  for (const id of ["activity", "activityRefresh", "recordLocalCheck",
    "activityList", "activityFeedback"]) {
    assert.ok(html.includes('id="' + id + '"'), id);
  }
  assert.match(html, /id="recordLocalCheck"[^>]+disabled/);
  assert.match(html, /Local observations have durable receipts/);
  assert.match(html, /No task was submitted/);
});

test("local activity uses only authenticated same-origin Headless APIs", () => {
  assert.match(js, /fetch\("\/api\/tasks\/v1\?limit=10"/);
  assert.match(js, /"X-Bifrost-Token": sessionToken/);
  assert.match(js, /if \(!token \|\| token !== sessionToken\)/);
  assert.match(js, /kind: "local.status.snapshot"/);
  assert.match(js, /crypto.randomUUID/);
  assert.match(js, /addEventListener\("click", recordLocalCheck\)/);
  assert.match(js, /document.createElement\("strong"\)/);
  assert.match(js, /name.textContent = "Local status check/);
  assert.doesNotMatch(js, /activityList"\)\.innerHTML/);
  assert.doesNotMatch(js, /remote\.submit|shell\.exec|cloud\.execute/);
});

test("offline PWA cannot show stale receipts or cache private APIs", () => {
  assert.match(js, /activityList"\)\.replaceChildren\(\)/);
  assert.match(js, /No live Headless session; local receipts hidden/);
  assert.match(sw, /url.pathname.startsWith\("\/api\/"\)/);
  assert.doesNotMatch(sw, /["']\/api\/tasks/);
});
