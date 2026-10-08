// Real-browser end-to-end check for Lucas Raven (BIFROST ZERO).
// Drives headless Chrome over CDP at iPhone viewport:
//   pair via #key= link -> render live node state -> Keep awake (30 min)
//   -> verify the macOS power assertion independently with pmset -> Release
//   -> verify the assertion is gone.
// Usage: RAVEN_OPERATOR_KEY=... node tests/browser_e2e.mjs [outdir]
import { spawn, execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from "node:fs";
import { tmpdir, homedir } from "node:os";
import { join } from "node:path";

const URL_BASE = process.env.RAVEN_URL || "https://lucas-raven.pages.dev";
const KEY = process.env.RAVEN_OPERATOR_KEY;
const OUT = process.argv[2] || tmpdir();
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
if (!KEY) throw new Error("RAVEN_OPERATOR_KEY not set");

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const evidence = [];
const note = (k, v) => { evidence.push({ k, v }); console.log(k.padEnd(28), typeof v === "string" ? v : JSON.stringify(v)); };

function assertionFor(pid) {
  const out = execFileSync("/usr/bin/pmset", ["-g", "assertions"], { encoding: "utf8" });
  return out.split("\n").some((l) => l.includes(`pid ${pid}(caffeinate)`));
}
const managedPid = () => {
  try { return JSON.parse(readFileSync(join(homedir(), ".eden/bifrost/remote-provider.json"), "utf8")).keep_awake_pid; }
  catch { return null; }
};

const profile = mkdtempSync(join(tmpdir(), "raven-e2e-"));
const port = 9339;
const chrome = spawn(CHROME, ["--headless=new", `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
  "--no-first-run", "--no-default-browser-check", "about:blank"], { stdio: "ignore" });
let ws, seq = 0;
const pending = new Map();
const send = (method, params = {}) => new Promise((ok, bad) => {
  const id = ++seq; pending.set(id, { ok, bad }); ws.send(JSON.stringify({ id, method, params }));
});
const evalJS = async (expr) => (await send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true })).result.value;
const waitFor = async (expr, ms = 60000) => {
  const t = Date.now();
  while (Date.now() - t < ms) { const v = await evalJS(expr); if (v) return v; await sleep(500); }
  throw new Error("timeout waiting for: " + expr);
};

let pass = false;
try {
  let target;
  for (let i = 0; i < 40 && !target; i++) {
    await sleep(250);
    try { target = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find((t) => t.type === "page"); } catch {}
  }
  ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener("open", r, { once: true }));
  ws.addEventListener("message", (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) { const p = pending.get(m.id); pending.delete(m.id); m.error ? p.bad(new Error(m.error.message)) : p.ok(m.result); }
  });
  await send("Runtime.enable");
  await send("Emulation.setDeviceMetricsOverride", { width: 390, height: 844, deviceScaleFactor: 3, mobile: true });
  await send("Emulation.setUserAgentOverride", { userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1 RavenE2E" });

  // 1. Unpaired load shows pairing UI, no data.
  await send("Page.navigate", { url: URL_BASE + "/" });
  await waitFor("document.readyState==='complete' && !document.getElementById('pair').hidden");
  note("unpaired_shows_pair", true);

  // 2. Pair through the fragment link.
  await send("Page.navigate", { url: `${URL_BASE}/#key=${KEY}` });
  await waitFor("!document.getElementById('app').hidden && document.querySelectorAll('#caps .card').length>0");
  note("fragment_stripped", await evalJS("!location.hash && !location.href.includes('key=')"));
  note("badge", await evalJS("document.getElementById('nodeBadge').textContent"));
  note("capability_cards", await evalJS("[...document.querySelectorAll('#caps .card')].map(c=>c.querySelector('h4').textContent+'='+c.querySelector('.chip').textContent)"));
  note("keepawake_before", await evalJS("document.getElementById('kaChip').textContent"));

  // 3. Keep awake 30 min via the UI.
  await evalJS("document.querySelector('#kaMinutes [data-min=\"30\"]').click(); document.getElementById('kaStart').click(); true");
  const startLine = await waitFor("(t=>/SUCCEEDED|FAILED|EXPIRED/.test(t)&&t)(document.getElementById('actionLine').textContent)", 90000);
  note("start_action", startLine);
  await waitFor("document.getElementById('kaChip').textContent==='RUNNING'", 30000);
  const pid = managedPid();
  note("managed_caffeinate_pid", pid);
  note("pmset_assertion_present", !!pid && assertionFor(pid));
  note("ui_keepawake_line", await evalJS("document.getElementById('kaLine').textContent"));
  const shot = await send("Page.captureScreenshot", { format: "png", captureBeyondViewport: true });
  writeFileSync(join(OUT, "raven-e2e-iphone.png"), Buffer.from(shot.data, "base64"));

  // 4. Release via the UI.
  await sleep(1000);
  await evalJS("document.getElementById('kaStop').click(); true");
  const stopLine = await waitFor("(t=>/power.keepawake.stop: (SUCCEEDED|FAILED|EXPIRED)/.test(t)&&t)(document.getElementById('actionLine').textContent)", 90000);
  note("stop_action", stopLine);
  await sleep(500);
  note("pmset_assertion_after_stop", !!pid && assertionFor(pid));
  await waitFor("document.getElementById('kaChip').textContent==='STOPPED'", 30000);
  note("keepawake_after", "STOPPED");
  note("activity_rows", await evalJS("[...document.querySelectorAll('#activity .act')].slice(0,2).map(r=>r.textContent.slice(0,140))"));

  const ev = Object.fromEntries(evidence.map((e) => [e.k, e.v]));
  pass = ev.unpaired_shows_pair && ev.fragment_stripped && /SUCCEEDED/.test(ev.start_action)
    && ev.pmset_assertion_present && /SUCCEEDED/.test(ev.stop_action) && !ev.pmset_assertion_after_stop;
} catch (e) {
  note("error", String(e.stack || e));
} finally {
  try { ws && ws.close(); } catch {}
  chrome.kill("SIGTERM");
  await sleep(500);
  rmSync(profile, { recursive: true, force: true });
  writeFileSync(join(OUT, "raven-e2e-evidence.json"), JSON.stringify({ at: new Date().toISOString(), pass, evidence }, null, 2));
  console.log(pass ? "E2E PASS" : "E2E FAIL");
  process.exit(pass ? 0 : 1);
}
