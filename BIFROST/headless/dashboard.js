"use strict";
const $ = id => document.getElementById(id);
const sectionNames = {headless:"Headless",caffeinate:"Caffeinate"};
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
  for (const id of ["awakeToggle", "openNativeApp", "save", "refreshSetups", "activityRefresh", "recordLocalCheck"]) {
    const button = $(id); if (button) button.disabled = false;
  }
  const headless = data.headless?.status === "running";
  const awake = data.caffeinate || {};
  prefs = data.preferences || prefs;
  $("overall").textContent = headless ? "● Headless running" : "Unavailable";
  $("overall").dataset.health = headless ? "running" : "offline";
  $("headlessState").textContent = headless ? "Running · PID " + data.headless.pid : "Offline";
  $("headlessState").dataset.health = headless ? "running" : "offline";
  $("awakeState").textContent = awake.active ? (awake.expiresAt ? "Until " + new Date(awake.expiresAt * 1000).toLocaleTimeString() : "On until stopped") : "Off";
  $("awakeToggle").textContent = awake.active ? "Stop" : ("Start " + (prefs.caffeinateMinutes === 0 ? "until stopped" : prefs.caffeinateMinutes + "m"));
  $("sumHeadless").textContent = "Headless: " + (headless ? "On" : "Off");
  $("sumAwake").textContent = "Caffeinate: " + (awake.active ? "On" : "Off");
  for (const [section] of Object.entries(sectionNames)) {
    document.querySelectorAll('[data-section="' + section + '"]').forEach(el => el.hidden = !prefs.dashboardSections.includes(section));
  }
  renderPrefs(prefs);
  if (typeof shellUpdateStatus === "function") shellUpdateStatus(data);
}
function renderPrefs(settings) {
  $("showHeadless").checked = settings.statusIndicators.includes("headless");
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
  clearStoragePreview();
  // Never keep stale provider account labels visible after losing authorization.
  if ($("firstUseResults")) $("firstUseResults").replaceChildren();
  if ($("firstUseFeedback")) $("firstUseFeedback").textContent = "Unavailable · Headless disconnected.";
  // A previous live observation cannot remain labeled "Running" after API loss.
  $("overall").textContent = "Unavailable · connection lost";
  $("overall").dataset.health = "offline";
  for (const id of ["headlessState", "awakeState", "sumHeadless", "sumAwake"]) {
    const label = $(id); if (label) label.textContent = "Unknown / offline";
  }
  for (const id of ["awakeToggle", "openNativeApp", "save", "refreshSetups", "activityRefresh", "recordLocalCheck"]) {
    const button = $(id); if (button) button.disabled = true;
  }
  document.querySelectorAll("#setupPackages button").forEach(button => { button.disabled = true; });
  if ($("kernelState")) $("kernelState").textContent = "Unknown / offline";
  if ($("kernelCounts")) $("kernelCounts").textContent = "Unavailable";
  if ($("kernelResults")) $("kernelResults").replaceChildren();
  if ($("kernelSearch")) $("kernelSearch").disabled = true;
  if ($("kernelRefresh")) $("kernelRefresh").disabled = true;
  if ($("kernelFeedback")) $("kernelFeedback").textContent = "No live Node connection; cached results cleared.";
  if ($("activityList")) $("activityList").replaceChildren();
  if ($("activityFeedback")) $("activityFeedback").textContent = "No live Headless session; local receipts hidden.";
  if ($("pwaLocalStatus")) $("pwaLocalStatus").textContent = "Unavailable";
  if ($("pwaOfflineStatus")) $("pwaOfflineStatus").textContent = "Static shell only";
  if ($("orchestrationCatalog")) $("orchestrationCatalog").replaceChildren();
  if ($("folderRuleState")) $("folderRuleState").textContent = "Unknown / offline";
  if ($("orchestrationState")) $("orchestrationState").textContent = "Offline";
  if ($("orchestrationRefresh")) $("orchestrationRefresh").disabled = true;
  if (typeof shellMarkOffline === "function") shellMarkOffline();
  message("No live Node connection. Actions disabled. " + (reason || ""));
}
async function refresh() {
  try {
    // Renew the loopback-only token after a Headless restart. No token is
    // persisted in the PWA or placed in a URL, cache or service worker.
    token = (await request("/api/session")).token;
    updateView(await request("/api/state"));
    await loadLocalActivity();
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
  await loadOrchestration();
  await loadKernelIndex();
  if (!poller) poller = setInterval(refresh, 30000);
}
$("refresh").addEventListener("click", refresh);
$("openNativeApp").addEventListener("click", async () => {
  if (!token) { markNodeOffline("Headless session unavailable."); return; }
  try {
    const result = await request("/api/control", {action: "app.open"});
    message(result.accepted
      ? "macOS accepted the native BIFROST launch request. Window visibility is not verified."
      : "Native BIFROST launch was not accepted.");
  } catch (error) {
    message("Cannot open BIFROST: " + error.message);
  }
});
$("awakeToggle").addEventListener("click", () => control(
  $("awakeToggle").textContent === "Stop" ? "caffeinate.stop" : "caffeinate.start",
  $("awakeToggle").textContent === "Stop" ? undefined : Number($("duration").value)
));
$("save").addEventListener("click", async () => {
  const indicators = [];
  if ($("showHeadless").checked) indicators.push("headless");
  const dashboardSections = [...document.querySelectorAll("[data-section-choice]:checked")].map(el=>el.dataset.sectionChoice);
  try {
    await request("/api/preferences", {
      statusIndicators:indicators,
      caffeinateMinutes:Number($("duration").value),dashboardSections
    });
    $("saved").textContent = "Saved";await refresh();
  } catch(error) { $("saved").textContent = error.message; }
});
start();

/* The browser never supplies a path or script. Only exact saved workflows
   in Headless's freshly discovered catalog can be submitted. */
async function loadOrchestration() {
  const target = $("orchestrationCatalog");
  if (!target) return;
  const button = $("orchestrationRefresh");
  if (!token) {
    target.replaceChildren();
    $("folderRuleState").textContent = "Unknown · Headless disconnected";
    $("orchestrationState").textContent = "Offline";
    $("orchestrationFeedback").textContent = "No workflow submitted.";
    button.disabled = true;
    return;
  }
  button.disabled = true;
  try {
    const res = await fetch("/api/orchestration/v1", {
      headers: {"X-Bifrost-Token":token}, cache:"no-store"
    });
    const json = await res.json();
    if (!res.ok) throw Error(json.error || "Workflow catalog unavailable");
    const status = json.status || {};
    const rule = status.rule;
    $("folderRuleState").textContent = status.ruleError ? "Refused · " + status.ruleError :
      !rule ? "No approved folder" : (rule.enabled ? "Approved and enabled" : "Approved · disabled");
    $("orchestrationState").textContent = status.serviceActive ? status.status : "Not running";
    target.replaceChildren();
    const items = [...(json.catalog?.shortcuts || []), ...(json.catalog?.automator || [])];
    for (const item of items) {
      const row = document.createElement("div"); row.className = "record";
      const name = document.createElement("div"); name.className = "record-info";
      const heading = document.createElement("strong"); heading.textContent = item.name;
      const detail = document.createElement("small"); detail.textContent = item.kind === "shortcut" ?
        "Apple Shortcut · inspect its actions before allowing execution" :
        "Saved Automator · can access other files or applications";
      name.append(heading, detail);
      const run = document.createElement("button"); run.type = "button";
      run.textContent = "Run…";
      run.addEventListener("click", async () => {
        if (!window.confirm("Run saved " + item.kind + " workflow “" + item.name +
                            "” on this Mac? It may change files and request permissions.")) return;
        run.disabled = true;
        try {
          const outcome = await request("/api/orchestration/v1",
            {action:"workflow.run",kind:item.kind,id:item.id,confirmed:true});
          const receipt = outcome.receipt;
          $("orchestrationFeedback").textContent = "Executor returned " +
            receipt.exitStatus + " · effects not independently verified.";
        } catch (error) {
          $("orchestrationFeedback").textContent = error.message;
        } finally { run.disabled = false; }
      });
      row.append(name, run);target.append(row);
    }
    if (!items.length) {
      const row = document.createElement("div");row.className = "record";
      row.textContent = "No available saved Shortcuts or Automator workflows.";
      target.append(row);
    }
  } catch (error) {
    target.replaceChildren();
    $("orchestrationFeedback").textContent = error.message;
  } finally { button.disabled = !token; }
}
$("orchestrationRefresh").addEventListener("click", loadOrchestration);


/* Durable LOCAL observation receipts. No remote tasks or executable actions. */
async function loadLocalActivity() {
  const target = $("activityList");
  if (!target) return;
  if (!token) {
    target.replaceChildren();
    $("activityFeedback").textContent = "Local session unavailable; no requests submitted.";
    $("activityRefresh").disabled = true;
    $("recordLocalCheck").disabled = true;
    if (typeof shellActivityUnknown === "function") shellActivityUnknown();
    return;
  }
  const sessionToken = token;
  try {
    const response = await fetch("/api/tasks/v1?limit=10", {
      headers: {"X-Bifrost-Token": sessionToken}, cache: "no-store"
    });
    const data = await response.json();
    if (!token || token !== sessionToken) {
      // Never restore a receipt view belonging to an expired/replaced session.
      target.replaceChildren();
      if (typeof shellActivityUnknown === "function") shellActivityUnknown();
      return;
    }
    if (!response.ok) throw Error(data.error || "Local activity unavailable");
    target.replaceChildren();
    for (const receipt of data.tasks || []) {
      const row = document.createElement("div");
      row.className = "record";
      const details = document.createElement("div");
      details.className = "record-info";
      const name = document.createElement("strong");
      name.textContent = "Local status check · " + receipt.state;
      const description = document.createElement("small");
      description.textContent = new Date(receipt.createdAt).toLocaleString() +
        " · " + receipt.taskId + " · local observation only";
      details.append(name, description);
      row.append(details);
      target.append(row);
    }
    if (!(data.tasks || []).length) {
      const empty = document.createElement("div");
      empty.className = "record";
      empty.textContent = "No recorded local checks.";
      target.append(empty);
    }
    $("activityFeedback").textContent = "Receipts are stored locally. No remote execution performed.";
    if (typeof shellUpdateActivity === "function") shellUpdateActivity((data.tasks || []).length);
  } catch (error) {
    target.replaceChildren();
    $("activityFeedback").textContent = "Local activity unavailable: " + error.message;
    if (typeof shellActivityUnknown === "function") shellActivityUnknown();
  }
}
async function recordLocalCheck() {
  if (!token) return;
  const button = $("recordLocalCheck");
  button.disabled = true;
  try {
    // Retry-safe opaque handle; never store provider credentials in this queue.
    const key = crypto.randomUUID ? crypto.randomUUID() : undefined;
    const receipt = await request("/api/tasks/v1", {
      kind: "local.status.snapshot", ...(key ? {idempotencyKey:key} : {})
    });
    $("activityFeedback").textContent = "Recorded " + receipt.taskId +
      " · local status only; no external job submitted.";
    await loadLocalActivity();
  } catch (error) {
    $("activityFeedback").textContent = "Could not record local status: " + error.message;
  } finally {
    button.disabled = !token;
  }
}
$("activityRefresh").addEventListener("click", loadLocalActivity);
$("recordLocalCheck").addEventListener("click", recordLocalCheck);

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
$("refreshSetups").addEventListener("click", loadSetupPackages);
loadSetupPackages();


/* PWA representation adapter: same-origin local Headless only.
 * No network proxy, external provider or remote execution. */
async function loadPwaAdapter() {
  try {
    const descriptor = await request("/api/pwa/adapter");
    $("pwaLocalStatus").textContent =
      descriptor.transport === "same-origin-loopback" &&
      descriptor.node?.status === "running" ? "Local Node connected" : "Unverified transport";
    $("pwaOfflineStatus").textContent = "Static only when disconnected";
  } catch (_) {
    $("pwaLocalStatus").textContent = "Unavailable";
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
    "This localhost dashboard connects only to the current device. Other devices require an independent installed connector.";
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



/* BIFROST Web shell: the HEADLESS state API is authoritative.
   A static specialist catalog is NOT an app registry. BIFROST Headless is
   the only component identified live; other specialists are unconnected
   shortcuts until a versioned authenticated app registry exists. */
const shellApps = Object.freeze([
  {id:"bifrost",name:"BIFROST",icon:"◠",group:"Local",
    kind:"Installed Headless",note:"Native window and local Headless are independent.",
    capabilities:[
      {name:"Headless controls",target:"status"},
      {name:"Local activity",target:"activity",min:"advanced"},
      {name:"Indexed files",target:"kernel",min:"advanced"},
      {name:"Saved Apple workflows",target:"orchestration",min:"advanced"},
      {name:"Install & Setup",target:"setups",min:"advanced"}]},
  {id:"heimdall",name:"HEIMDALL",icon:"◫",group:"Specialists",
    kind:"Workspace specialist",note:"Workspace and user/staff interface composition. Not connected to this Headless listener.",
    capabilities:[]},
  {id:"janitor",name:"JANITOR",icon:"♧",group:"Specialists",
    kind:"Maintenance specialist",note:"File and system maintenance remains a separate authorized capability. Integration unverified.",
    capabilities:[]},
  {id:"penelope",name:"PENELOPE",icon:"▤",group:"Specialists",
    kind:"File custody specialist",note:"Authorized file organization and account scope belong to PENELOPE. Integration unverified.",
    capabilities:[]},
  {id:"curator",name:"CURATOR",icon:"▧",group:"Specialists",
    kind:"Media specialist",note:"Media review and professional automation through its own domain. Integration unverified.",
    capabilities:[]}
]);
let shellMode = "simple";
let shellLayout = "gallery";
let shellSelectedApp = "bifrost";
let shellSelectedCapability = 0;
let shellQuery = "";
let shellNodeRunning = false;
const shellNode = (tag, cls, value) => {
  const item = document.createElement(tag);
  if (cls) item.className = cls;
  if (value !== undefined) item.textContent = value;
  return item;
};
// Simple navigation exposes actual dashboard destinations, never new authority.
const shellSidebarTargets = Object.freeze([
  ["sidebarHome","webHomePanel"],
  ["sidebarConnections","webConnectionsPanel"],
  ["sidebarApps","appBrowser"],
  ["sidebarMac","webMacPanel"],
  ["sidebarActivity","webActivityPanel"],
  ["sidebarActions","webQuickActionsPanel"],
  ["sidebarSettings","settingsPanel"]
]);
function shellMarkSidebar(target) {
  if (!shellSidebarTargets.some(([, section]) => section === target)) return;
  for (const [buttonId, section] of shellSidebarTargets) {
    const button = $(buttonId);
    if (button) button.setAttribute("aria-current", section === target ? "page" : "false");
  }
}
function shellSelectApp(id) {
  if (!shellApps.some(app => app.id === id)) return;
  shellSelectedApp = id;
  shellSelectedCapability = 0;
  shellRenderBrowser();
  shellJump("appBrowser");
}
function shellJump(id) {
  const element = $(id);
  if (!element) return;
  // Once the verified Web shell mounts, sidebar and action navigation use
  // distinct hash-routed subpages, not scrolling to sections of one page.
  if (typeof window !== "undefined" && shellRouteMounted) {
    const route = shellPageForTarget(id);
    if (route) {
      const needed = shellRouteDefinitions[route].level;
      if (levels[shellMode] < levels[needed]) {
        shellNavigatePage("settings");
        $("experienceDescription").textContent =
          "This tool requires " + needed + " detail. Choose it in Settings, then return to the tool.";
        return;
      }
      shellNavigatePage(route);
      return;
    }
  }
  const minimum = element.dataset.minLevel || "simple";
  if (levels[shellMode] < levels[minimum]) {
    // Never silently elevate detail or hide the requested page behind a popover.
    // Navigate to the SAME Settings destination shown in the sidebar.
    const settings = $("settingsPanel");
    if (settings) settings.scrollIntoView({behavior:"auto",block:"start"});
    shellMarkSidebar("settingsPanel");
    const description = $("experienceDescription");
    if (description) description.textContent =
      "This tool requires " + minimum + " detail. Choose it here, then return to the tool.";
    return;
  }
  element.scrollIntoView({behavior:"auto",block:"start"});
  shellMarkSidebar(id);
}
function shellSetLayout(layout) {
  if (!["list","columns","gallery"].includes(layout)) return;
  shellLayout = layout;
  document.querySelectorAll("[data-app-layout]").forEach(button =>
    button.setAttribute("aria-pressed", String(button.dataset.appLayout === layout)));
  shellRenderBrowser();
}
/* The Dock resolves a Web representation, never an arbitrary script or
   a guessed URL. Current Headless authoritatively verifies only its own
   same-origin Web UI; specialist Web URLs require a real verified app registry. */
// Launch only an observed, identity-matched app Web representation from the
// existing authenticated connection snapshot. Never trust a manifest URL,
// inferred port, plugin catalog, or arbitrary backend-injected destination.
const shellApprovedWebURLs = Object.freeze({
  heimdall: "http://127.0.0.1:8787/",
  penelope: "http://127.0.0.1:8765/"
});
function shellWebDestination(app) {
  if (!shellNodeRunning) return null;
  if (app.id === "bifrost") return "/";
  if (typeof token !== "string" || !token || typeof window === "undefined") return null;
  const approved = shellApprovedWebURLs[app.id];
  if (!approved) return null;
  const observation = window.BifrostConnections?.apps?.find(item => item.id === app.id);
  return observation?.webVerified === true && observation.webURL === approved
    ? approved : null;
}
function shellRenderSpectrum() {
  const target = $("webSpectrum");
  if (!target) return;
  target.replaceChildren();
  let verified = 0;
  for (const app of shellApps) {
    const connected = shellWebDestination(app) !== null;
    if (connected) verified++;
    const path = shellNode("span","web-spectrum-path");
    path.dataset.connection = app.id;
    path.dataset.state = connected ? "connected" : "unverified";
    path.setAttribute("role","img");
    path.setAttribute("aria-label", app.name + " · " +
      (connected ? "Web connection verified" : "No verified Web connection"));
    path.setAttribute("title",app.name + " · " +
      (connected ? "Web UI available" : "Connection not verified"));
    target.append(path);
  }
  const label = $("webSpectrumStatus");
  if (label) label.textContent = verified + " verified local Web UI" +
    (verified === 1 ? "" : "s") + " · " +
    (shellApps.length - verified) + " unverified app paths";
}
function shellRenderDock({skipObserverRedraw = false} = {}) {
  const dock = $("webDock");
  const favorites = $("webFavorites");
  dock.replaceChildren();
  favorites.replaceChildren();
  for (const app of shellApps) {
    const webURL = shellWebDestination(app);
    // Real anchor navigation in a new browser tab. No window.open popup,
    // no tab URL containing a session token, no external URL invented.
    const dockButton = shellNode(webURL ? "a" : "button","web-dock-button");
    if (webURL) {
      dockButton.setAttribute("href",webURL);
      dockButton.setAttribute("target","_blank");
      dockButton.setAttribute("rel","noopener noreferrer");
      dockButton.setAttribute("aria-label","Open " + app.name + " Web UI");
    } else {
      dockButton.type = "button";
      dockButton.setAttribute("aria-label","Inspect " + app.name + " connection · Web UI not verified");
      dockButton.setAttribute("title","Inspect connection · No verified Web UI URL");
      dockButton.addEventListener("click",() => shellSelectApp(app.id));
    }
    dockButton.append(shellNode("span","",app.icon),shellNode("span","",app.name));
    dock.append(dockButton);
    const favorite = shellNode(webURL ? "a" : "button","web-favorite");
    if (webURL) {
      favorite.setAttribute("href",webURL);
      favorite.setAttribute("target","_blank");
      favorite.setAttribute("rel","noopener noreferrer");
      favorite.setAttribute("aria-label","Open " + app.name + " Web UI");
    } else {
      favorite.type = "button";
      favorite.setAttribute("aria-label","Inspect " + app.name + " connection");
      favorite.addEventListener("click",() => shellSelectApp(app.id));
    }
    favorite.append(shellNode("span","",app.icon),shellNode("span","",app.name),
      shellNode("small","",webURL ? "Open Web UI ↗" : "Inspect connection"));
    favorites.append(favorite);
  }
  shellRenderSpectrum();
  shellRenderConnections();
  if (!skipObserverRedraw && typeof window !== "undefined" &&
      typeof window.BifrostConnectionRender === "function") {
    window.BifrostConnectionRender();
  }
}
// A graphical, read-only map of the SAME confirmed Web representations as
// the spectral paths and Dock. Unknown specialist URLs are never constructed.
function shellRenderConnections() {
  const target = $("webConnectionTiles");
  if (!target) return;
  target.replaceChildren();
  let verified = 0;
  for (const app of shellApps) {
    const connected = shellWebDestination(app) !== null;
    if (connected) verified++;
    const tile = shellNode("div","web-connection-tile");
    tile.dataset.connection = app.id;
    tile.dataset.state = connected ? "connected" : "unverified";
    tile.setAttribute("role","listitem");
    tile.setAttribute("aria-label", app.name + " · " +
      (connected ? "Web UI connected" : "Web UI not verified"));
    const glyph = shellNode("span","web-connection-glyph",app.icon);
    glyph.setAttribute("aria-hidden","true");
    const copy = shellNode("span","web-connection-copy");
    copy.append(shellNode("strong","",app.name),
      shellNode("small","",connected ? "Web UI connected" : "Not yet verified"));
    tile.append(glyph,copy,shellNode("span","web-connection-state"));
    target.append(tile);
  }
  const count = $("webConnectionCount");
  if (count) count.textContent = verified + " of " + shellApps.length +
    " Web connections verified";
}
function shellAppState(app) {
  const observation = typeof window === "undefined" ? null :
    window.BifrostConnections?.apps?.find(item => item.id === app.id);
  if (observation?.webVerified) return "Verified app Web UI";
  if (observation?.nativeTestCandidate) return "Mac test build observed · Web UI not verified";
  if (observation?.chatgptPluginObserved) return "ChatGPT plugin catalogued · Web UI not verified";
  return app.id === "bifrost" ?
    (shellNodeRunning ? "Local service observed" : "Headless unavailable") :
    "Integration unverified";
}
function shellRenderBrowser() {
  const view = $("webAppView");
  const detail = $("webAppDetail");
  if (!view || !detail) return;
  view.replaceChildren();
  detail.replaceChildren();
  const q = shellQuery.toLocaleLowerCase();
  const visible = shellApps.filter(app =>
    (app.name + " " + app.kind + " " + app.note + " " +
     app.capabilities.map(item => item.name).join(" ")).toLocaleLowerCase().includes(q));
  const liveApps = shellApps.filter(item => shellWebDestination(item) !== null).length;
  $("webBrowseCount").textContent = visible.length + " catalog entries · " +
    liveApps + " verified local Web representation" + (liveApps === 1 ? "" : "s");
  if (!visible.some(app => app.id === shellSelectedApp) && visible.length) {
    shellSelectedApp = visible[0].id;
    shellSelectedCapability = 0;
  }
  const selected = visible.find(app => app.id === shellSelectedApp);
  if (shellLayout === "list") {
    const head = shellNode("div","web-browser-row web-browser-head");
    ["Application","Role","Connection"].forEach(label => head.append(shellNode("span","",label)));
    view.append(head);
    for (const app of visible) {
      const row = shellNode("button","web-browser-row");
      row.type = "button";
      row.setAttribute("aria-selected",String(app.id === shellSelectedApp));
      const title = shellNode("span","web-browser-name");
      title.append(shellNode("span","web-browser-icon",app.icon),shellNode("span","",app.name));
      row.append(title,shellNode("span","",app.kind),shellNode("small","",shellAppState(app)));
      row.addEventListener("click",() => shellSelectRow(app.id));
      view.append(row);
    }
  } else if (shellLayout === "columns") {
    const columns = shellNode("div","web-columns");
    const collection = shellNode("div","web-column");
    const appColumn = shellNode("div","web-column");
    const capabilityColumn = shellNode("div","web-column");
    [ [collection,"Collections"],[appColumn,"Applications"],[capabilityColumn,"Functions"] ].forEach(
      ([col,name])=>col.append(shellNode("div","web-column-title",name)));
    for (const group of ["Local","Specialists"]) {
      const row = shellNode("button","web-browser-item",group + " ›");
      row.type = "button";
      row.setAttribute("aria-selected",String(selected?.group === group));
      row.addEventListener("click",() => {
        const next = visible.find(app=>app.group === group);
        if (next) shellSelectRow(next.id);
      });
      collection.append(row);
    }
    for (const app of visible.filter(item => !selected || item.group === selected.group)) {
      const row = shellNode("button","web-browser-item",app.icon + "  " + app.name + " ›");
      row.type = "button";row.setAttribute("aria-selected",String(app.id === shellSelectedApp));
      row.addEventListener("click",() => shellSelectRow(app.id));
      appColumn.append(row);
    }
    if (selected) {
      for (const [i, capability] of selected.capabilities.entries()) {
        const row = shellNode("button","web-browser-item",capability.name + " ›");
        row.type = "button";row.setAttribute("aria-selected",String(i === shellSelectedCapability));
        row.addEventListener("click",() => {shellSelectedCapability=i;shellRenderBrowser();});
        capabilityColumn.append(row);
      }
      if (!selected.capabilities.length) capabilityColumn.append(
        shellNode("div","setup-explain","No verified callable functions"));
    }
    columns.append(collection,appColumn,capabilityColumn);
    view.append(columns);
  } else {
    const gallery = shellNode("div","web-gallery");
    for (const app of visible) {
      const row = shellNode("button","web-browser-item");
      row.type = "button";row.setAttribute("aria-selected",String(app.id === shellSelectedApp));
      row.append(shellNode("span","web-browser-icon",app.icon),
        shellNode("strong","",app.name),shellNode("small","",shellAppState(app)));
      row.addEventListener("click",() => shellSelectRow(app.id));
      gallery.append(row);
    }
    view.append(gallery);
  }
  if (!visible.length) {
    view.append(shellNode("p","setup-explain","No matching application catalog entries."));
    detail.append(shellNode("p","setup-explain","No matching application."));
    return;
  }
  detail.append(shellNode("span","web-browser-icon",selected.icon),
    shellNode("h3","",selected.name),
    shellNode("p","",selected.kind + " · " + shellAppState(selected)),
    shellNode("p","",selected.note));
  const verifiedWebURL = shellWebDestination(selected);
  if (verifiedWebURL) {
    const openWeb = shellNode("a","web-open-ui","Open " + selected.name + " Web UI ↗");
    openWeb.setAttribute("href",verifiedWebURL);
    openWeb.setAttribute("target","_blank");
    openWeb.setAttribute("rel","noopener noreferrer");
    detail.append(openWeb,
      shellNode("small","","Verified same-origin Web UI. Individual actions still require their original permissions."));
  } else detail.append(shellNode("div","web-unconnected",
    "No verified Web UI representation for this app. Register and verify its own destination before opening."));
  detail.append(shellNode("h4","","Functions"));
  if (selected.capabilities.length) {
    for (const [i, capability] of selected.capabilities.entries()) {
      const button = shellNode("button","",capability.name + " ›");
      button.type="button";
      button.addEventListener("click",() => {
        shellSelectedCapability = i;
        shellJump(capability.target);
      });
      detail.append(button);
    }
  } else detail.append(shellNode("p","","No authenticated app-core capability registry entry is available."));
}
function shellSelectRow(id) {
  shellSelectedApp = id;
  shellSelectedCapability = 0;
  shellRenderBrowser();
}
function shellUpdateStatus(data) {
  shellNodeRunning = data.headless?.status === "running";
  $("homeHeadless").textContent = shellNodeRunning ? "Connected locally" : "Unavailable";
  $("homeObservation").textContent = "Observed locally " + new Date().toLocaleTimeString();
  $("sideNodeStatus").textContent = shellNodeRunning ? "Headless · local running" : "Headless · unavailable";
  $("homeConnections").textContent = shellNodeRunning ? "1 verified local Web UI" : "No verified local Web UI";
  $("homeApps").textContent = shellNodeRunning ? "BIFROST only" : "Unverified";
  $("webAttention").textContent = "Only local BIFROST is checked here. Additional applications appear after their own Web connections are verified.";
  shellRenderBrowser();
  shellRenderDock();
}
function shellMarkOffline() {
  shellNodeRunning = false;
  $("homeHeadless").textContent = "Unknown / disconnected";
  $("homeObservation").textContent = "Last observation invalidated";
  $("sideNodeStatus").textContent = "Headless · unavailable";
  $("homeApps").textContent = "Unverified";
  $("homeConnections").textContent = "Local path offline · specialists unverified";
  $("homeActivity").textContent = "Unavailable";
  $("webAttention").textContent = "Headless connection unavailable. No actions or specialist status can be verified.";
  shellRenderBrowser();
  shellRenderDock();
}
function shellUpdateActivity(count) {
  $("homeActivity").textContent = count === 0 ? "No recorded checks" : count + " recent local checks";
}
function shellActivityUnknown() {
  $("homeActivity").textContent = "Unavailable";
}
function shellApplyExperience(mode) {
  shellMode = mode;
  shellSetLayout(mode === "expert" ? "columns" : mode === "advanced" ? "list" : "gallery");
  // Same runtime authority; disclosure never adds capability or permissions.
}
function shellInit() {
  const nav = document.querySelector('nav[aria-label="Dashboard shortcuts"]');
  if (nav) $("sidebarNavMount").append(nav);
  for (const [buttonId, sectionId] of shellSidebarTargets) {
    const button = $(buttonId);
    if (button) button.addEventListener("click",() => shellJump(sectionId));
  }
  shellMarkSidebar("webHomePanel");
  $("webHome").addEventListener("click",() => shellJump("webHomePanel"));
  $("webRefresh").addEventListener("click",refresh);
  $("webViewDetails").addEventListener("click",() => shellJump("status"));
  $("appSearch").addEventListener("input",event => {
    shellQuery = event.target.value.trim().slice(0,100);
    shellRenderBrowser();
  });
  $("appSearch").addEventListener("keydown",event=>{
    if (event.key === "Enter") shellJump("appBrowser");
  });
  document.querySelectorAll("[data-app-layout]").forEach(button=>
    button.addEventListener("click",() => shellSetLayout(button.dataset.appLayout)));
  document.querySelectorAll("[data-bifrost-jump]").forEach(button=>
    button.addEventListener("click",() => shellJump(button.dataset.bifrostJump)));
  shellRenderDock();
  shellSetLayout("gallery");
}
shellInit();

/* Three different experiences over the SAME local authority.
   Simple: essential state only. Advanced: configuration and approved
   workflows. Expert: read-only identity/evidence inspection. Mode selection
   does not grant permission, start Headless, or cache session credentials. */
let experienceMode = "simple";
const levels = {simple:0,advanced:1,expert:2};
const modeDescriptions = {
  simple:"Connected applications and the essentials. Advanced tools remain out of the way.",
  advanced:"Manage saved Apple workflows, local index, setups and Headless preferences. Actions still require confirmation.",
  expert:"Inspect live runtime identity and provenance in addition to Advanced tools. No extra execution authority."
};
function setExperienceMode(mode) {
  if (!Object.hasOwn(levels, mode)) return;
  experienceMode = mode;
  document.querySelectorAll("[data-min-level]").forEach(element => {
    const required = element.dataset.minLevel || "simple";
    element.hidden = levels[mode] < levels[required];
  });
  for (const item of Object.keys(levels)) {
    const button = $("mode" + item[0].toUpperCase() + item.slice(1));
    button.setAttribute("aria-pressed", String(item === mode));
    button.classList.toggle("selected", item === mode);
  }
  $("experienceDescription").textContent = modeDescriptions[mode];
  if (typeof shellApplyExperience === "function") shellApplyExperience(mode);
  if (mode === "expert" && token) loadExpertDiagnostics();
  if (mode !== "simple" && token) loadOrchestration();
}
async function loadExpertDiagnostics() {
  const refreshButton = $("diagnosticsRefresh");
  if (!refreshButton || experienceMode !== "expert") return;
  refreshButton.disabled = true;
  try {
    const response = await fetch("/api/health", {cache:"no-store"});
    const result = await response.json();
    if (!response.ok || !result.ok ||
        result.identity?.schema !== "bifrost.headless.identity.v1" ||
        result.identity?.productId !== "eden.bifrost.headless") {
      throw Error("No matching BIFROST local listener");
    }
    $("expertProduct").textContent = result.identity.productId;
    $("expertRuntime").textContent = result.identity.runtimeId || "Unavailable";
    $("expertSource").textContent = result.identity.sourceSha256 || "Unavailable";
    $("expertFeedback").textContent = "Observed local identity only; physical/macOS permissions are not verified.";
  } catch (error) {
    for (const id of ["expertProduct","expertRuntime","expertSource"]) {
      $(id).textContent = "Unknown / offline";
    }
    $("expertFeedback").textContent = error.message;
  } finally {
    refreshButton.disabled = false;
  }
}
for (const item of Object.keys(levels)) {
  $("mode" + item[0].toUpperCase() + item.slice(1))
    .addEventListener("click", () => setExperienceMode(item));
}
$("diagnosticsRefresh").addEventListener("click", loadExpertDiagnostics);
setExperienceMode("simple");


/* BIFROST subpage routing (APPLE UX, owner request 2026-10-20).
 * One persistent app shell; distinct hash-addressable views using the
 * existing, secured DOM. No new endpoints, credentials, registration,
 * embedded external WebKit, or Headless service permissions. */
const shellRouteDefinitions = Object.freeze({
  home:          {target:"webHomePanel",level:"simple",label:"Home",sidebar:"webHomePanel"},
  connections:   {target:"webHomePanel",level:"simple",label:"Connections",sidebar:"webConnectionsPanel"},
  apps:          {target:"appBrowser",level:"simple",label:"Applications",sidebar:"appBrowser"},
  mac:           {target:"status",level:"simple",label:"This Mac",sidebar:"webMacPanel"},
  activity:      {target:"activity",level:"simple",label:"Activity",sidebar:"webActivityPanel"},
  actions:       {target:"webHomePanel",level:"simple",label:"Quick Actions",sidebar:"webQuickActionsPanel"},
  settings:      {target:"settingsPanel",level:"simple",label:"Settings",sidebar:"settingsPanel"},
  interconnect:  {target:"interconnect",level:"advanced",label:"Local PWA",sidebar:null},
  orchestration: {target:"orchestration",level:"advanced",label:"Apple Workflows",sidebar:null},
  kernel:        {target:"kernel",level:"advanced",label:"Index & Identity",sidebar:null},
  setups:        {target:"setups",level:"advanced",label:"Install & Setup",sidebar:null},
  diagnostics:   {target:"diagnostics",level:"expert",label:"Diagnostics",sidebar:null}
});
const shellRouteTargets = Object.freeze({
  webHomePanel:"home", webConnectionsPanel:"connections", appBrowser:"apps",
  webMacPanel:"mac", status:"mac", webActivityPanel:"activity", activity:"activity",
  webQuickActionsPanel:"actions", settingsPanel:"settings", preferences:"settings",
  interconnect:"interconnect", orchestration:"orchestration", kernel:"kernel",
  setups:"setups", diagnostics:"diagnostics"
});
const shellTopLevelPages = Object.freeze([
  "webHomePanel","appBrowser","settingsPanel","status","orchestration",
  "activity","interconnect","kernel","setups","diagnostics"
]);
let shellRouteMounted = false;

function shellPageForTarget(id) {
  return Object.hasOwn(shellRouteTargets,id) ? shellRouteTargets[id] : null;
}
function shellActivatePage(requested) {
  let route = Object.hasOwn(shellRouteDefinitions,requested) ? requested : "home";
  let page = shellRouteDefinitions[route];
  const denied = levels[shellMode] < levels[page.level];
  if (denied) {
    const needed = page.level;
    route = "settings";
    page = shellRouteDefinitions.settings;
    $("experienceDescription").textContent =
      "This destination requires " + needed + " detail. Choose it here first.";
  }
  for (const id of shellTopLevelPages) {
    const region = $(id);
    if (region) region.hidden = id !== page.target;
  }
  const content = document.querySelector(".web-content");
  if (content) content.dataset.bifrostPage = route;
  shellMarkSidebar(page.sidebar);
  const heading = document.querySelector(".web-topbar-identity .sub");
  if (heading) heading.textContent = page.label;
  document.title = "BIFROST · " + page.label;
  const nav = document.querySelector('nav[aria-label="Dashboard shortcuts"]');
  if (nav) {
    nav.querySelectorAll("a[href^='#']").forEach(anchor => {
      if (shellPageForTarget(anchor.getAttribute("href").slice(1)) === route)
        anchor.setAttribute("aria-current","page");
      else anchor.removeAttribute("aria-current");
    });
  }
  const sidebar = document.querySelector(".web-sidebar");
  if (sidebar) sidebar.dataset.menuOpen = "false";
  const toggle = $("sidebarMenuToggle");
  if (toggle) toggle.setAttribute("aria-expanded","false");
  return route;
}
function shellNavigatePage(route) {
  if (!shellRouteMounted || !Object.hasOwn(shellRouteDefinitions,route)) return;
  const actual = shellActivatePage(route);
  const desired = "#/" + actual;
  if (window.location.hash !== desired) window.location.hash = desired;
  if (typeof window.scrollTo === "function") window.scrollTo(0,0);
}
function shellSyncPageFromHash() {
  const hash = window.location.hash.replace(/^#\/?/,"");
  const page = Object.hasOwn(shellRouteDefinitions,hash)
    ? hash : (shellPageForTarget(hash) || "home");
  shellActivatePage(page);
}
function shellInstallRoutes() {
  if (typeof window === "undefined" ||
      !document.querySelector(".web-content") ||
      !document.querySelector(".web-sidebar")) return;
  const sidebar = document.querySelector(".web-sidebar");
  sidebar.dataset.menuOpen = "false";
  const brand = document.querySelector(".web-brand");
  if (brand) {
    const toggle = document.createElement("button");
    toggle.id = "sidebarMenuToggle";
    toggle.type = "button";
    toggle.className = "web-nav-toggle";
    toggle.textContent = "Menu";
    toggle.setAttribute("aria-label","BIFROST navigation menu");
    toggle.setAttribute("aria-controls","sidebarNavMount");
    toggle.setAttribute("aria-expanded","false");
    toggle.addEventListener("click",() => {
      const opened = sidebar.dataset.menuOpen !== "true";
      sidebar.dataset.menuOpen = String(opened);
      toggle.setAttribute("aria-expanded",String(opened));
    });
    brand.append(toggle);
  }
  const tools = document.querySelector('nav[aria-label="Dashboard shortcuts"]');
  if (tools) tools.addEventListener("click",event => {
    const anchor = event.target.closest("a[href^='#']");
    if (!anchor) return;
    const page = shellPageForTarget(anchor.getAttribute("href").slice(1));
    if (!page) return;
    event.preventDefault();
    shellJump(anchor.getAttribute("href").slice(1));
  });
  window.addEventListener("hashchange", shellSyncPageFromHash);
  shellRouteMounted = true;
  shellSyncPageFromHash();
}
shellInstallRoutes();


// Storage uses the existing profile-bound backend and session; never a raw path.
let storageGeneration = 0;
function clearStoragePreview() {
  storageGeneration++;
  if ($("storageResults")) $("storageResults").replaceChildren();
  if ($("storageFeedback")) $("storageFeedback").textContent = "No current preview.";
}
async function browseStorage(readRemote) {
  clearStoragePreview();
  const generation = storageGeneration;
  const session = token;
  if (!session) { $("storageFeedback").textContent = "Connect to Headless first."; return; }
  const profile = $("storageProfile").value.trim();
  const folder = $("storageFolder").value.trim();
  if (!profile) { $("storageFeedback").textContent = "Enter an existing saved profile name."; return; }
  $("storageFeedback").textContent = "Reading selected folder…";
  try {
    const result = await request("/api/storage/v1/preview", {profile, folder, readRemote});
    if (generation !== storageGeneration || session !== token) return;
    $("storageFeedback").textContent = result.status + " · " + (result.count ?? 0) + " entries";
    for (const entry of result.entries || []) {
      const row = document.createElement("div"); row.className = "record";
      row.textContent = entry.name + " · " + entry.kind + (entry.bytes == null ? "" : " · " + entry.bytes + " bytes");
      $("storageResults").append(row);
    }
  } catch (error) {
    if (generation === storageGeneration && session === token)
      $("storageFeedback").textContent = "Preview unavailable: " + error.message;
  }
}
$("storagePreview")?.addEventListener("click", () => browseStorage(false));
$("storageOnline")?.addEventListener("click", () => browseStorage(true));
for (const id of ["storageProfile", "storageFolder"]) $(id)?.addEventListener("input", clearStoragePreview);


/* First use extends the SAME Headless instance and its session; no signup or sync. */
async function refreshFirstUseAccounts() {
  const results = $("firstUseResults"), feedback = $("firstUseFeedback");
  if (!results || !feedback) return;
  results.replaceChildren();
  if (!token) { feedback.textContent = "No authenticated local Headless session."; return; }
  const originalSession = token;
  feedback.textContent = "Inspecting saved account labels…";
  try {
    const response = await fetch("/api/connections/first-use/v1",
      {headers: {"X-Bifrost-Token": originalSession}, cache: "no-store"});
    const data = await response.json();
    if (token !== originalSession) return;
    if (!response.ok) throw Error(data.error || "Account labels unavailable");
    const rdc = data.rdc || {}, cloud = data.cloud || {};
    const rows = [
      "RDC installed manager: " + (rdc.installedManagerFound ? "found" : "not detected"),
      "RDC saved labels: " + ((rdc.profileLabels || []).join(", ") || "none found"),
      "RDCravensnest device: UNKNOWN — not authenticated or checked",
      "RDC7: reserved for a different future account",
      ...((cloud.configuredRemoteLabels || []).map(x =>
        "Cloud remote label: " + x.provider + " / " + x.remoteLabel +
        " (" + x.configSource + ") — owner and OAuth NOT VERIFIED"))
    ];
    for (const line of rows) {
      const row = document.createElement("div");
      row.className = "record";
      row.textContent = line;
      results.append(row);
    }
    feedback.textContent = "Read-only discovery finished. No account/device changed.";
  } catch (error) {
    if (token === originalSession) feedback.textContent = "Inventory unavailable: " + error.message;
  }
}
$("firstUseRefresh")?.addEventListener("click", refreshFirstUseAccounts);
