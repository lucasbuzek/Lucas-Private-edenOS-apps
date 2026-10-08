"use strict";
// Lucas Raven client. No secrets ship in this file: the operator key is entered
// by the user (or arrives in a #key= pairing fragment, which never reaches the
// server) and is kept in this device's storage only.
(() => {
  const KEY = "raven.operatorKey";
  const NODE = "lucas-macbook";
  const $ = (id) => document.getElementById(id);
  const store = {
    get() { try { return localStorage.getItem(KEY); } catch { return null; } },
    set(v) { try { localStorage.setItem(KEY, v); } catch {} },
    clear() { try { localStorage.removeItem(KEY); } catch {} },
  };
  let key = null, minutes = 60, timer = null, pendingId = null;

  const TITLES = {
    node: "Mac", "power.keepawake": "Keep Awake", "remote.provider": "Remote bridge",
    "bifrost.app": "BIFROST app", codex: "Codex", github: "GitHub", claude_code: "Claude Code",
    cloudflare: "Cloudflare", registry: "EDEN Apps",
  };
  const ORDER = ["node", "power.keepawake", "github", "codex", "claude_code", "cloudflare",
    "remote.provider", "bifrost.app", "registry"];
  const TONE = { RUNNING: "s-ok", AUTHENTICATED: "s-ok", AVAILABLE: "s-warn", CREDENTIAL_PRESENT: "s-warn",
    OBSERVED: "s-info", STOPPED: "s-dim", NOT_INSTALLED: "s-bad", ERROR: "s-bad", UNKNOWN: "s-warn" };

  function el(tag, cls, text) {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }
  function ago(ms) {
    const s = Math.max(0, Math.round(ms / 1000));
    if (s < 60) return s + "s ago";
    if (s < 3600) return Math.round(s / 60) + "m ago";
    return Math.round(s / 3600) + "h ago";
  }
  function clock(tsSec) {
    return new Date(tsSec * 1000).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }

  async function api(path, opts = {}) {
    const res = await fetch("/api/" + path, {
      ...opts, cache: "no-store",
      headers: { authorization: "Bearer " + key, "content-type": "application/json" },
    });
    const data = await res.json().catch(() => ({}));
    if (res.status === 401) { unpair("This device's key was rejected. Pair again."); throw new Error("unauthorized"); }
    if (!res.ok) throw new Error(data.error || "HTTP " + res.status);
    return data;
  }

  // ------------------------------------------------------------ pairing
  function extractKey(text) {
    const t = (text || "").trim();
    const m = t.match(/#key=([A-Za-z0-9]{32,128})/) || t.match(/^([A-Za-z0-9]{32,128})$/);
    return m ? m[1] : null;
  }
  function showPair(msg) {
    $("pair").hidden = false; $("app").hidden = true; $("unpair").hidden = true;
    setBadge("off", "Not paired");
    const e = $("pairErr"); e.hidden = !msg; e.textContent = msg || "";
  }
  async function pair(k) {
    key = k;
    try {
      await api("state");
      store.set(k);
      $("pair").hidden = true; $("app").hidden = false; $("unpair").hidden = false;
      start();
    } catch (e) {
      key = null;
      if (e.message !== "unauthorized") showPair("Could not reach Raven: " + e.message);
    }
  }
  function unpair(msg) {
    store.clear(); key = null; if (timer) clearInterval(timer); timer = null; showPair(msg);
  }

  // ------------------------------------------------------------ render
  function setBadge(kind, text) {
    const b = $("nodeBadge"); b.replaceChildren(el("span", "dot " + kind), el("span", null, text));
  }

  function render(data) {
    const node = data.nodes.find((n) => n.node_id === NODE) || data.nodes[0];
    if (!node) {
      setBadge("off", "No BIFROST node has reported");
      $("caps").replaceChildren(el("p", "muted", "Waiting for the Mac bridge to publish state."));
      renderActivity(data); setControls(false); return;
    }
    setBadge(node.online ? "" : "stale", (node.meta.hostname || node.node_id) + (node.online ? " · online " : " · offline · last ") + ago(node.age_s * 1000));
    setControls(node.online);
    const caps = node.state.capabilities || {};
    const keys = ORDER.filter((k) => k in caps).concat(Object.keys(caps).filter((k) => !ORDER.includes(k)));
    const nowSec = data.now / 1000;
    $("caps").replaceChildren(...keys.map((k) => card(k, caps[k], nowSec)));
    renderKeepAwake(caps["power.keepawake"]);
    renderActivity(data);
  }

  function card(id, c, nowSec) {
    const d = el("article", "card");
    const head = el("div", "head");
    head.append(el("h4", null, TITLES[id] || id), el("span", "chip " + (TONE[c.status] || "s-dim"), c.status));
    d.append(head, el("div", "sum", c.summary || ""));
    if (c.evidence && c.evidence.length) {
      const ul = el("ul"); c.evidence.slice(0, 5).forEach((e) => ul.append(el("li", null, e))); d.append(ul);
    }
    if (id === "registry" && Array.isArray(c.apps)) {
      d.append(el("div", "sum", c.apps.map((a) => `${a.name} ${a.lifecycle}`).join(" · ")));
    }
    if (c.checked_at) d.append(el("div", "when", "checked " + ago((nowSec - c.checked_at) * 1000)));
    return d;
  }

  function renderKeepAwake(c) {
    const chip = $("kaChip");
    if (!c) { chip.textContent = "UNKNOWN"; chip.className = "chip s-warn"; $("kaLine").textContent = "No state reported."; return; }
    chip.textContent = c.status; chip.className = "chip " + (TONE[c.status] || "s-dim");
    let line;
    if (c.status === "RUNNING") {
      line = "BIFROST is holding a native power assertion" + (c.until ? " until " + clock(c.until) : " (no time limit)") + ".";
      line += c.assertion_verified ? " Verified in pmset." : " Not yet seen in pmset.";
    } else {
      line = "No BIFROST assertion. System idle sleep currently " + (c.system_sleep_prevented ? "prevented by another process." : "allowed.");
    }
    $("kaLine").textContent = line;
  }

  function renderActivity(data) {
    const box = $("activity");
    if (!data.actions.length) { box.replaceChildren(el("p", "muted", "No actions yet.")); return; }
    box.replaceChildren(...data.actions.map((a) => {
      const row = el("div", "act");
      const label = (data.catalog[a.capability] || {}).label || a.capability;
      const p = Object.entries(a.params || {}).map(([k, v]) => `${k}=${v}`).join(" ");
      row.append(el("div", null, label + (p ? " · " + p : "")));
      const tone = { succeeded: "s-ok", failed: "s-bad", expired: "s-bad", queued: "s-warn", claimed: "s-info" }[a.status];
      row.append(el("span", "chip " + (tone || "s-dim"), a.status.toUpperCase()));
      const took = a.completed_at ? ` · ${((a.completed_at - a.created_at) / 1000).toFixed(1)}s round trip` : "";
      const res = a.result ? " · " + JSON.stringify(a.result).slice(0, 140) : "";
      row.append(el("div", "meta", `${ago(data.now - a.created_at)}${took}${res} · ${a.id}`));
      return row;
    }));
  }

  function setControls(online) {
    ["kaStart", "kaStop", "refresh"].forEach((id) => { $(id).disabled = !online || !!pendingId; });
  }

  // ------------------------------------------------------------ actions
  async function request(capability, params) {
    const line = $("actionLine");
    try {
      pendingId = "…"; setControls(true);
      line.textContent = "Requesting " + capability + "…";
      const r = await api("actions", { method: "POST", body: JSON.stringify({ node_id: NODE, capability, params }) });
      pendingId = r.id;
      line.textContent = "Queued " + r.id + (r.node_online ? "; waiting for the Mac…" : "; the Mac is offline.");
      for (let i = 0; i < 40; i++) {
        await new Promise((ok) => setTimeout(ok, 1500));
        const a = await api("actions/" + r.id);
        if (["succeeded", "failed", "expired"].includes(a.status)) {
          const secs = a.completed_at ? ((a.completed_at - a.created_at) / 1000).toFixed(1) + "s" : "";
          line.textContent = `${capability}: ${a.status.toUpperCase()} ${secs}` + (a.result && a.result.error ? " — " + a.result.error : "");
          break;
        }
      }
    } catch (e) {
      line.textContent = "Request failed: " + e.message;
    } finally {
      pendingId = null; await refresh();
    }
  }

  async function refresh() {
    if (!key) return;
    try { render(await api("state")); } catch (e) { if (e.message !== "unauthorized") setBadge("stale", "Raven unreachable"); }
  }
  function start() {
    refresh();
    if (timer) clearInterval(timer);
    timer = setInterval(() => { if (!document.hidden) refresh(); }, 5000);
  }

  // ------------------------------------------------------------ wire up
  $("kaMinutes").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-min]"); if (!b) return;
    minutes = Number(b.dataset.min);
    [...$("kaMinutes").children].forEach((x) => x.classList.toggle("on", x === b));
  });
  $("kaStart").addEventListener("click", () => request("power.keepawake.start", { minutes }));
  $("kaStop").addEventListener("click", () => request("power.keepawake.stop", {}));
  $("refresh").addEventListener("click", () => request("bifrost.state.refresh", {}));
  $("unpair").addEventListener("click", () => unpair());
  $("pairForm").addEventListener("submit", (e) => {
    e.preventDefault();
    const k = extractKey($("pairInput").value); $("pairInput").value = "";
    if (!k) return showPair("That doesn't look like a Raven pairing link or key.");
    pair(k);
  });
  document.addEventListener("visibilitychange", () => { if (!document.hidden) refresh(); });

  const fromHash = extractKey(location.hash);
  if (fromHash) history.replaceState(null, "", location.pathname);
  const saved = fromHash || store.get();
  if (saved) pair(saved); else showPair();
})();
