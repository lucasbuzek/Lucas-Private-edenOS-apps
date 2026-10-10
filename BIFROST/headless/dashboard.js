"use strict";
const $ = id => document.getElementById(id);
const sectionNames = {headless:"Headless",tasks:"Tasks",caffeinate:"Caffeinate",raven:"Raven",ai:"AI"};
let token = null;
let prefs = null;
let poller = null;
const message = text => { $("feedback").textContent = text; };
async function request(path, payload) {
  const options = payload === undefined ? {} : {
    method:"POST",headers:{"Content-Type":"application/json","X-Bifrost-Token":token},body:JSON.stringify(payload)
  };
  const response = await fetch(path, options);
  const json = await response.json();
  if (!response.ok) throw Error(json.error || ("HTTP " + response.status));
  return json;
}
function updateView(data) {
  for (const id of ["awakeToggle", "refreshTasks", "save", "refreshSetups"]) {
    const button = $(id); if (button) button.disabled = false;
  }
  const headless = data.headless?.status === "running";
  const task = data.tasks || {};
  const awake = data.caffeinate || {};
  prefs = data.preferences || prefs;
  $("overall").textContent = headless ? "● Headless running" : "Unavailable";
  $("overall").dataset.health = headless ? "running" : "offline";
  $("headlessState").textContent = headless ? "Running · PID " + data.headless.pid : "Offline";
  $("headlessState").dataset.health = headless ? "running" : "offline";
  $("taskCount").textContent = task.status === "observed" ? String(task.active) + " active" : "Unknown";
  $("taskDetail").textContent = task.status === "observed" ? String(task.total) + " latest tasks observed" : "Read-only status · " + (task.status || "unknown");
  $("awakeState").textContent = awake.active ? (awake.expiresAt ? "Until " + new Date(awake.expiresAt * 1000).toLocaleTimeString() : "On until stopped") : "Off";
  $("awakeToggle").textContent = awake.active ? "Stop" : ("Start " + (prefs.caffeinateMinutes === 0 ? "until stopped" : prefs.caffeinateMinutes + "m"));
  $("ravenState").textContent = data.raven?.bridge || "Unknown";
  $("ravenState").dataset.health = data.raven?.bridge === "running" ? "running" : "unknown";
  $("aiState").textContent = (data.ai?.routing || "auto") + " · provider not connected";
  $("sumHeadless").textContent = "Headless: " + (headless ? "On" : "Off");
  $("sumTasks").textContent = "Tasks: " + (task.status === "observed" ? task.active : "Unknown");
  $("sumAwake").textContent = "Caffeinate: " + (awake.active ? "On" : "Off");
  $("sumRaven").textContent = "Raven: " + (data.raven?.bridge || "Unknown");
  for (const [section] of Object.entries(sectionNames)) {
    document.querySelectorAll('[data-section="' + section + '"]').forEach(el => el.hidden = !prefs.dashboardSections.includes(section));
  }
  if (document.activeElement?.id !== "aiRoute") renderPrefs(prefs);
}
function renderPrefs(settings) {
  $("showHeadless").checked = settings.statusIndicators.includes("headless");
  $("showTasks").checked = settings.statusIndicators.includes("activeTasks");
  $("aiRoute").value = settings.aiRouting;
  $("duration").value = String(settings.caffeinateMinutes);
  $("sectionOptions").replaceChildren();
  for (const [id,name] of Object.entries(sectionNames)) {
    const label = document.createElement("label");
    const cb = document.createElement("input");cb.type = "checkbox";cb.dataset.sectionChoice = id;
    cb.checked = settings.dashboardSections.includes(id);
    label.append(cb, " " + name);$("sectionOptions").append(label);
  }
}
function markNodeOffline(reason) {
  // A previous live observation cannot remain labeled "Running" after API loss.
  $("overall").textContent = "Unavailable · connection lost";
  $("overall").dataset.health = "offline";
  for (const id of ["headlessState", "taskCount", "awakeState", "ravenState",
                    "sumHeadless", "sumTasks", "sumAwake", "sumRaven"]) {
    const label = $(id); if (label) label.textContent = "Unknown / offline";
  }
  for (const id of ["awakeToggle", "refreshTasks", "save", "refreshSetups"]) {
    const button = $(id); if (button) button.disabled = true;
  }
  document.querySelectorAll("#setupPackages button").forEach(button => { button.disabled = true; });
  if ($("kernelState")) $("kernelState").textContent = "Unknown / offline";
  if ($("kernelCounts")) $("kernelCounts").textContent = "Unavailable";
  if ($("kernelResults")) $("kernelResults").replaceChildren();
  if ($("kernelSearch")) $("kernelSearch").disabled = true;
  if ($("kernelRefresh")) $("kernelRefresh").disabled = true;
  if ($("kernelFeedback")) $("kernelFeedback").textContent = "No live Node connection; cached results cleared.";
  if ($("pwaLocalStatus")) $("pwaLocalStatus").textContent = "Unavailable";
  if ($("pwaRemoteStatus")) $("pwaRemoteStatus").textContent = "Unverified";
  if ($("pwaOfflineStatus")) $("pwaOfflineStatus").textContent = "Static shell only";
  message("No live Node connection. Actions disabled. " + (reason || ""));
}
async function refresh() {
  try {
    // Renew the loopback-only token after a Headless restart. No token is
    // persisted in the PWA or placed in a URL, cache or service worker.
    token = (await request("/api/session")).token;
    updateView(await request("/api/state"));
    message("");
    return true;
  } catch(error) {
    token = null;
    markNodeOffline(error.message);
    return false;
  }
}
async function control(action, minutes) {
  if (!token) { markNodeOffline("Headless session unavailable."); return; }
  try { await request("/api/control", {action, ...(minutes === undefined ? {} : {minutes})});await refresh(); }
  catch(error) { message(error.message); if (/401|403|unauthorized/i.test(error.message)) { token = null; await refresh(); } }
}
async function start() {
  await refresh();
  await loadKernelIndex();
  if (!poller) poller = setInterval(refresh, 30000);
}
$("refresh").addEventListener("click", refresh);
$("refreshTasks").addEventListener("click", () => control("tasks.refresh"));
$("awakeToggle").addEventListener("click", () => control(
  $("awakeToggle").textContent === "Stop" ? "caffeinate.stop" : "caffeinate.start",
  $("awakeToggle").textContent === "Stop" ? undefined : Number($("duration").value)
));
$("save").addEventListener("click", async () => {
  const indicators = [];
  if ($("showHeadless").checked) indicators.push("headless");
  if ($("showTasks").checked) indicators.push("activeTasks");
  const dashboardSections = [...document.querySelectorAll("[data-section-choice]:checked")].map(el=>el.dataset.sectionChoice);
  try {
    await request("/api/preferences", {
      statusIndicators:indicators,aiRouting:$("aiRoute").value,
      caffeinateMinutes:Number($("duration").value),dashboardSections
    });
    $("saved").textContent = "Saved";await refresh();
  } catch(error) { $("saved").textContent = error.message; }
});
start();

async function loadSetupPackages() {
  const target = $("setupPackages");
  if (!target) return;
  try {
    const result = await request("/api/setup/catalog");
    target.replaceChildren();
    for (const pkg of result.packages || []) {
      const row = document.createElement("div");
      row.className = "record setup-row";
      row.dataset.feature = pkg.id === "ai-toolkit" ? "ai" : "apps";
      const identity = document.createElement("div");
      identity.className = "record-name";
      const glyph = document.createElement("span");
      glyph.className = "feature-glyph";
      glyph.setAttribute("aria-hidden", "true");
      glyph.textContent = pkg.id === "ai-toolkit" ? "✳" : "▦";
      const description = document.createElement("div");
      const label = document.createElement("strong");
      label.textContent = pkg.name;
      const details = document.createElement("small");
      details.textContent = (pkg.archive_name || "Archive unavailable") +
        " · " + (pkg.status || "unknown") + " · installation not verified";
      description.append(label, details);
      identity.append(glyph, description);
      row.append(identity);
      const controls = document.createElement("div");
      controls.className = "actions";
      const status = document.createElement("output");
      status.textContent = pkg.status || "unknown";
      controls.append(status);
      if (pkg.status === "available") {
        const stage = document.createElement("button");
        stage.type = "button";
        stage.textContent = "Stage for review";
        stage.addEventListener("click", async () => {
          if (!window.confirm("Stage " + pkg.name +
            " for local review? No installer will run and no account will be changed.")) return;
          stage.disabled = true;
          try {
            const staged = await request("/api/setup/stage", {id:pkg.id});
            $("setupFeedback").textContent =
              staged.status === "staged" ? pkg.name + " staged safely; installation NOT performed." :
                "Staging returned an unexpected state";
            await loadSetupPackages();
          } catch(error) {
            $("setupFeedback").textContent = error.message;
            stage.disabled = false;
          }
        });
        controls.append(stage);
      }
      if (pkg.status === "invalid" && pkg.error) {
        details.textContent = pkg.error + " · rejected";
      }
      row.append(controls);
      target.append(row);
    }
    if (!(result.packages || []).length) {
      const blank = document.createElement("div");
      blank.className = "record";
      blank.textContent = "No supported packages discovered.";
      target.append(blank);
    }
  } catch(error) {
    target.textContent = "Setup package inventory unavailable: " + error.message;
  }
}
async function loadMobileBridge() {
  try {
    const result = await request("/api/mobile/bridge");
    $("mobileState").textContent = result.agent === "running" ?
      "Bridge agent running" : (result.agent || "Unknown");
    $("mobileGrant").textContent = result.mobilePairingVerified === true ?
      "Pairing verified" : "Pairing unverified";
  } catch(error) {
    $("mobileState").textContent = "Unknown";
    $("mobileGrant").textContent = "Unverified";
  }
}
$("refreshSetups").addEventListener("click", loadSetupPackages);
loadSetupPackages();
loadMobileBridge();


/* PWA representation adapter: same-origin Headless, explicit remote provider link.
 * No browser-side proxy, service-worker API cache or remote installation grant. */
async function loadPwaAdapter() {
  try {
    const descriptor = await request("/api/pwa/adapter");
    $("pwaLocalStatus").textContent =
      descriptor.transport === "same-origin-loopback" &&
      descriptor.node?.status === "running" ? "Local Node connected" : "Unverified transport";
    const provider = descriptor.optionalRemoteProvider || {};
    $("pwaRemoteStatus").textContent = provider.agent === "running"
      ? "Agent running · pairing unverified" : "Not verified";
    $("pwaOfflineStatus").textContent = "Static only when disconnected";
  } catch (_) {
    $("pwaLocalStatus").textContent = "Unavailable";
    $("pwaRemoteStatus").textContent = "Unverified";
    $("pwaOfflineStatus").textContent = "Static shell only";
  }
}
let deferredInstallPrompt = null;
window.addEventListener("beforeinstallprompt", event => {
  event.preventDefault();
  deferredInstallPrompt = event;
  $("installPwa").hidden = false;
  $("pwaInstallHelp").textContent = "BIFROST is available as a browser-installed PWA. Device access still requires approval.";
});
$("installPwa").addEventListener("click", async () => {
  if (!deferredInstallPrompt) return;
  const prompt = deferredInstallPrompt;
  deferredInstallPrompt = null;
  $("installPwa").hidden = true;
  await prompt.prompt();
});
window.addEventListener("appinstalled", () => {
  $("installPwa").hidden = true;
  $("pwaInstallHelp").textContent = "PWA installed. Installation does not grant Node permissions.";
});
if (/iPad|iPhone|iPod/.test(navigator.userAgent)) {
  $("pwaInstallHelp").textContent =
    "On iPhone/iPad, Safari Share → Add to Home Screen. This localhost page only connects to a Headless service running on this device; use Raven for a remote Mac.";
}
if ("serviceWorker" in navigator && window.isSecureContext) {
  navigator.serviceWorker.register("/sw.js", {scope: "/"}).catch(() => {
    $("pwaInstallHelp").textContent = "Service worker unavailable; live Headless dashboard still works.";
  });
}
window.addEventListener("offline", () => { refresh(); loadPwaAdapter(); });
window.addEventListener("online", () => {
  start();
  loadSetupPackages();
  loadMobileBridge();
  loadPwaAdapter();
});
loadPwaAdapter();

/* DP0.1 read-only PWA adapter: operational SQLite data is never cached in a SW. */
let kernelIndexAvailable = false;
async function loadKernelIndex() {
  try {
    const answer = await request("/api/kernel/status");
    $("kernelRefresh").disabled = false;
    const live = answer.state === "INDEX_AVAILABLE";
    kernelIndexAvailable = live;
    $("kernelState").textContent = live ? "Indexed" :
      (answer.state === "NOT_INDEXED" ? "Not indexed" : "Unavailable");
    $("kernelCounts").textContent = live
      ? String(answer.object_count || 0) + " objects · " +
        String(answer.source_count || 0) + " sources · " +
        String(answer.relationship_count || 0) + " relations"
      : "No verified index";
    $("kernelSearch").disabled = !live || !token;
    if (!live) $("kernelResults").replaceChildren();
    $("kernelFeedback").textContent = live
      ? "Search is locally authorized. Files and metadata never enter the service-worker cache."
      : "Choose a folder from the macOS App's Index & Identity view to populate this index.";
  } catch (error) {
    kernelIndexAvailable = false;
    $("kernelState").textContent = "Unavailable";
    $("kernelCounts").textContent = "Unknown";
    $("kernelSearch").disabled = true;
    $("kernelResults").replaceChildren();
    $("kernelFeedback").textContent = "Index not available: " + error.message;
  }
}
async function performKernelSearch() {
  const term = $("kernelQuery").value.trim();
  if (!term || !token || !kernelIndexAvailable || term.length > 128) {
    $("kernelFeedback").textContent = "Enter a name/category (1–128 characters); local session required.";
    return;
  }
  const button = $("kernelSearch");
  button.disabled = true;
  try {
    const url = "/api/kernel/search?" + new URLSearchParams({q:term,limit:"40"});
    const response = await fetch(url, {headers:{"X-Bifrost-Token":token},cache:"no-store"});
    const data = await response.json();
    if (!response.ok) throw Error(data.error || "Search unavailable");
    const results = $("kernelResults");
    results.replaceChildren();
    for (const item of data.matches || []) {
      const row = document.createElement("div");
      row.className = "record";
      const identity = document.createElement("div");
      identity.className = "record-info";
      const name = document.createElement("strong");
      name.textContent = item.relative || "Unnamed";
      const description = document.createElement("small");
      description.textContent = (item.classification || "unknown") + " · " +
        (item.mime || "unknown") + " · " + String(item.bytes || 0) + " bytes";
      identity.append(name,description);
      row.append(identity);
      results.append(row);
    }
    $("kernelFeedback").textContent = (data.matches || []).length +
      " indexed location matches; live local Headless observation";
  } catch (error) {
    $("kernelResults").replaceChildren();
    $("kernelFeedback").textContent = "Search failed: " + error.message;
    if (/401|403|session|unauthoriz/i.test(error.message)) {
      token = null;
      await refresh();
    }
  } finally {
    button.disabled = !token || !kernelIndexAvailable;
  }
}
$("kernelRefresh").addEventListener("click", loadKernelIndex);
$("kernelSearch").addEventListener("click", performKernelSearch);
$("kernelQuery").addEventListener("keydown", event => {
  if (event.key === "Enter") performKernelSearch();
});
