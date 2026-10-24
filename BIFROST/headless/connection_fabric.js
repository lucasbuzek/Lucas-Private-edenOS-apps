"use strict";
/* BIFROST ZERO · live, typed local connections on the EXISTING Web shell.
 * No new auth agent, app registry, secret store or automatic network probing.
 * Spectral paths correspond to evidence-backed routes, never static decoration.
 */
(() => {
  const SCHEMA = "bifrost.connections.observation.v1";
  const el = id => document.getElementById(id);
  let timer = null;
  let activeRequest = false;
  let current = null;
  // Monitoring is an explicit, session-scoped opt-in. No background probes
  // before approval, after logout, when hidden or after a range change.
  let monitorState = null;
  let monitorTimer = null;
  let scanRequestBusy = false;

  function node(tag, cls, value) {
    const item = document.createElement(tag);
    if (cls) item.className = cls;
    if (value !== undefined) item.textContent = String(value);
    return item;
  }
  function row(target, name, detail, status, kind) {
    const item = node("div", "web-connection-tile fabric-entry");
    item.setAttribute("role", "listitem");
    item.dataset.state = status;
    const symbol = node("span", "web-connection-glyph", kind);
    symbol.setAttribute("aria-hidden", "true");
    const labels = node("span", "web-connection-copy");
    labels.append(node("strong", "", name), node("small", "", detail));
    item.append(symbol, labels, node("span", "web-connection-state"));
    target.append(item);
  }
  function invalidate(message) {
    stopMonitor("Monitoring stopped: local session or connection unavailable.");
    current = null;
    window.BifrostConnections = null;
    // Drop stale specialist launch links immediately on session loss.
    if (typeof shellRenderDock === "function") shellRenderDock({skipObserverRedraw:true});
    if (typeof shellRenderBrowser === "function") shellRenderBrowser();
    for (const id of ["connectionDeviceList", "connectionServices"]) {
      const target = el(id);
      if (target) target.replaceChildren();
    }
    if (el("connectionThisMac")) el("connectionThisMac").textContent = "This Mac · unavailable";
    if (el("connectionRDC")) el("connectionRDC").textContent = "RDC state unknown";
    if (el("connectionSubnet")) el("connectionSubnet").textContent =
      "No authenticated BIFROST Headless session; device observations cleared.";
    if (el("connectionScan")) el("connectionScan").disabled = true;
    if (el("connectionScanState")) el("connectionScanState").textContent =
      message || "Local session lost. No network state or permissions assumed.";
    if (el("homeConnections")) el("homeConnections").textContent = "Unknown · disconnected";
    if (el("webConnectionCount")) el("webConnectionCount").textContent = "Observation unavailable";
    if (typeof shellRenderSpectrum === "function") shellRenderSpectrum();
  }
  function renderSpectrum(data) {
    const root = el("webSpectrum");
    if (!root) return;
    root.replaceChildren();
    const paths = [
      {name: "BIFROST · this Mac", status: "connected"},
      {name: "RDC · " + (data.rdc.selected || "not selected"),
       status: data.rdc.selected ? "observed" : "unverified"},
      ...data.apps.filter(app => {
        const vettedURL = typeof shellWebDestination === "function"
          ? shellWebDestination({id:app.id}) : null;
        return app.webVerified === true && !!vettedURL &&
          vettedURL === app.webURL;
      }).map(app => ({
        name: app.name + " · verified Web UI", status: "connected"
      })),
      ...data.lan.observedPeers.slice(0, 8).map(peer => ({
        name: peer.address + " · " + (peer.state === "icmp-responded"
          ? "ICMP responding, no app trust" : "cached ARP, availability unknown"),
        status: peer.state === "icmp-responded" ? "observed" : "unverified"
      })),
      ...data.connectors.filter(c => c.id !== "rdc").slice(0, 5).map(item => ({
        name: item.name,
        status: item.state === "adapter-source-observed" ? "observed" : "unverified"
      }))
    ];
    for (const [i, connection] of paths.entries()) {
      const line = node("span", "web-spectrum-path");
      line.dataset.state = connection.status;
      line.dataset.connection = connection.name;
      line.style.top = (i * 4.5 + 2) + "px";
      line.style.setProperty("--path-color",
        ["#53e7ed", "#709dfb", "#aa85f8", "#ef9acb", "#ffaf77",
         "#72d3a6", "#80cbfd", "#dc9cf4"][i % 8]);
      line.setAttribute("role", "img");
      line.setAttribute("aria-label", connection.name + " · " + connection.status);
      line.title = connection.name + " · " + connection.status;
      root.append(line);
    }
    const confirmed = paths.filter(p => p.status === "connected").length;
    const observed = paths.filter(p => p.status === "observed").length;
    if (el("webSpectrumStatus")) el("webSpectrumStatus").textContent =
      confirmed + " verified local service · " + observed +
      " observed routes (not necessarily authorized) · " +
      data.lan.observedPeers.length + " network peers observed";
  }
  function render(data) {
    if (data?.schema !== SCHEMA || !data.thisDevice || !data.lan ||
        !Array.isArray(data.apps) || !Array.isArray(data.connectors)) {
      invalidate("Unrecognized connection observation");
      return;
    }
    current = data;
    window.BifrostConnections = data;
    const peers = data.lan.observedPeers;
    const detected = peers.filter(x => x.state === "icmp-responded").length;
    if (el("connectionThisMac")) el("connectionThisMac").textContent =
      "This Mac · " + data.thisDevice.name;
    if (el("connectionRDC")) el("connectionRDC").textContent =
      "RDC · " + (data.rdc.selected || "not selected") +
      " · provider authentication tracked separately";
    if (el("connectionSubnet")) el("connectionSubnet").textContent =
      (data.lan.interface || "Unknown interface") + " · " +
      (data.lan.address || "No local address") + " · " +
      (data.lan.subnet || "No approved LAN range") +
      " · passive refresh does not probe remote hosts";
    if (monitorState && monitorState.subnet !== data.lan.subnet)
      stopMonitor("Monitoring stopped: local network changed.");
    if (el("connectionScan")) el("connectionScan").disabled = !data.lan.subnet ||
      data.lan.scan.status === "scanning" || !!monitorState;
    if (el("connectionMonitorToggle")) el("connectionMonitorToggle").disabled = !data.lan.subnet;
    const scan = data.lan.scan;
    if (el("connectionScanState")) el("connectionScanState").textContent =
      scan.status === "scanning" ?
        "Scanning selected private LAN · " + scan.scanned + "/" + scan.total +
        " · " + scan.responders.length + " ICMP replies" :
      scan.status === "complete" ?
        "Completed " + scan.scanned + "/" + scan.total + " · " +
        scan.responders.length + " responses. Reachability ≠ pairing or app access." :
      scan.status === "stale" ? "Last scan expired · use Refresh or Scan again" :
      scan.status === "error" ? "LAN probe failed · no connected device inferred" :
        "Passive monitoring only. Scan is user-initiated and limited to 64 private-LAN addresses.";
    const devices = el("connectionDeviceList");
    if (devices) {
      devices.replaceChildren();
      if (!peers.length) {
        devices.append(node("p", "setup-explain",
          "No peers in ARP/ICMP observations yet. This does not mean the network is empty. " +
          "Use the range controls to inspect your LAN; native Bonjour discovery remains available in BIFROST App."));
      }
      for (const peer of peers) {
        const live = peer.state === "icmp-responded";
        row(devices, peer.address, live ?
          "Responded to ICMP · identity and authorization unverified" :
          "Previously observed in ARP cache · current reachability unknown",
          live ? "observed" : "unverified", "▣");
      }
    }
    const services = el("connectionServices");
    if (services) {
      services.replaceChildren();
      for (const app of data.apps) {
        const parts = [];
        if (app.nativeTestCandidate) parts.push("Mac test build on disk");
        if (app.chatgptPluginObserved) parts.push("ChatGPT plugin previously catalogued");
        if (!parts.length) parts.push("No qualified local test build observed");
        parts.push(app.webVerified ? "Web URL verified" : "Web UI not registered");
        row(services, app.name, parts.join(" · "),
            app.webVerified ? "connected" :
            app.nativeTestCandidate || app.chatgptPluginObserved ? "observed" : "unverified", "▦");
      }
      for (const connector of data.connectors) {
        row(services, connector.name,
          connector.state === "selected-local-profile" ?
            connector.detail : connector.type + " · " + connector.state,
          connector.state === "unverified" ? "unverified" : "observed", "⌁");
      }
    }
    if (el("homeConnections")) el("homeConnections").textContent =
      "This Mac · " + detected + " ICMP responders" +
      (peers.length > detected ? " · " + (peers.length - detected) + " cached" : "");
    if (el("homeApps")) el("homeApps").textContent =
      data.apps.filter(a=>a.nativeTestCandidate).length + " Mac test builds · " +
      data.apps.filter(a=>a.chatgptPluginObserved).length + " previously catalogued plugins";
    if (el("webConnectionCount")) el("webConnectionCount").textContent =
      "This Mac · " + peers.length + " peer observations · " +
      data.connectors.length + " connector entries";
    if (el("webAttention")) el("webAttention").textContent =
      data.lan.scan.status === "not-scanned" ?
      "Native Bonjour and LAN scanning exist in BIFROST App. This Web view will not scan automatically." :
      "Network response, installed source, registered ChatGPT plugin and authorized execution are separate states.";
    // One observation drives both Web launch destinations and luminous lines.
    // Skip the legacy callback on this path: it would re-enter render(current).
    if (typeof shellRenderBrowser === "function") shellRenderBrowser();
    if (typeof shellRenderDock === "function") shellRenderDock({skipObserverRedraw:true});
    renderSpectrum(data);
  }
  async function load() {
    if (activeRequest) return;
    if (typeof token !== "string" || !token) {
      invalidate("No authenticated local session; monitoring paused.");
      return;
    }
    activeRequest = true;
    const session = token;
    try {
      const response = await fetch("/api/connections/v1", {
        method: "GET", cache: "no-store",
        headers: {"X-Bifrost-Token": session}
      });
      if (!response.ok) throw new Error("Connection observation unavailable (" + response.status + ")");
      const data = await response.json();
      if (token !== session) { invalidate("Session changed; stale observations discarded."); return; }
      render(data);
    } catch (error) {
      invalidate(error.message);
    } finally {
      activeRequest = false;
    }
  }
  function selectedRange() {
    const start = Number(el("connectionRangeStart")?.value);
    const end = Number(el("connectionRangeEnd")?.value);
    if (!Number.isInteger(start) || !Number.isInteger(end) ||
        start < 1 || end > 254 || start > end || end - start + 1 > 64) {
      if (el("connectionScanState")) el("connectionScanState").textContent =
        "Select 1–64 consecutive hosts inside the displayed private subnet.";
      return null;
    }
    return {start, end};
  }
  function stopMonitor(message) {
    if (monitorTimer !== null) { clearInterval(monitorTimer); monitorTimer = null; }
    const wasRunning = monitorState !== null;
    monitorState = null;
    const control = el("connectionMonitorToggle");
    if (control) {
      control.setAttribute("aria-pressed", "false");
      control.textContent = "Monitor selected range…";
    }
    if (wasRunning && message && el("connectionScanState"))
      el("connectionScanState").textContent = message;
  }
  async function requestScan(range, session) {
    if (scanRequestBusy || !current || !current.lan.subnet || !session ||
        token !== session) return false;
    scanRequestBusy = true;
    try {
      const response = await fetch("/api/connections/scan", {
        method: "POST", cache: "no-store",
        headers: {"Content-Type": "application/json", "X-Bifrost-Token": session},
        body: JSON.stringify({start:range.start, end:range.end, confirmed:true})
      });
      const result = await response.json();
      if (token !== session) {
        invalidate("Session changed; selected range monitoring stopped.");
        return false;
      }
      if (!response.ok) {
        if (response.status === 422 && current.lan.scan.status === "scanning")
          return false;
        throw new Error(result.error || "LAN range request rejected");
      }
      await load();
      return true;
    } catch (error) {
      stopMonitor("Range monitoring stopped: " + error.message);
      if (el("connectionScanState")) el("connectionScanState").textContent =
        "Range scan unavailable · " + error.message;
      return false;
    } finally {
      scanRequestBusy = false;
    }
  }
  async function scan() {
    if (monitorState || !current?.lan?.subnet || !token) return;
    const range = selectedRange();
    if (!range || !window.confirm("Probe " + (range.end - range.start + 1) +
        " addresses in " + current.lan.subnet +
        "? Reachability never grants device access.")) return;
    await requestScan(range, token);
  }
  function monitorTick() {
    const active = monitorState;
    if (!active) return;
    if (document.hidden || token !== active.session ||
        !current || current.lan.subnet !== active.subnet) {
      stopMonitor("Monitoring stopped: page, session or network changed.");
      return;
    }
    if (current.lan.scan.status === "scanning" || scanRequestBusy) return;
    void requestScan({start:active.start, end:active.end}, active.session);
  }
  function toggleMonitor() {
    if (monitorState) { stopMonitor("Selected-range monitoring stopped."); return; }
    if (!current?.lan?.subnet || !token || document.hidden) return;
    const range = selectedRange();
    if (!range) return;
    const refresh = Number(el("connectionMonitorInterval")?.value || 30);
    const seconds = [15,30,60,120,300].includes(refresh)
      ? Math.max(30,refresh) : 30;
    if (!window.confirm("Monitor " + (range.end - range.start + 1) +
        " hosts on " + current.lan.subnet + " every " + seconds +
        " seconds while this browser tab is visible? This performs repeated ICMP probes. " +
        "Only local reachability is checked, never credentials or pairing.")) return;
    monitorState = {...range, subnet:current.lan.subnet, session:token, seconds};
    const control = el("connectionMonitorToggle");
    control.setAttribute("aria-pressed", "true");
    control.textContent = "Stop range monitoring";
    if (el("connectionScanState")) el("connectionScanState").textContent =
      "Monitoring selected LAN range every " + seconds + " seconds; stop at any time.";
    monitorTick();
    monitorTimer = setInterval(monitorTick, seconds * 1000);
  }
  function resetInterval() {
    if (timer) clearInterval(timer);
    const value = Number(el("connectionMonitorInterval")?.value || 30);
    const seconds = [15, 30, 60, 120, 300].includes(value) ? value : 30;
    timer = setInterval(load, seconds * 1000);
  }
  function init() {
    if (!el("connectionRefresh")) return;
    window.BifrostConnectionRender = () => {
      if (typeof token === "string" && token && current) render(current);
      else invalidate("No verified local session; cached connection states cleared.");
    };
    window.BifrostConnectionInvalidate = invalidate;
    el("connectionRefresh").addEventListener("click",load);
    el("connectionScan").addEventListener("click",scan);
    el("connectionMonitorToggle").addEventListener("click",toggleMonitor);
    // Altering a range or polling cadence revokes this tab's prior scan grant.
    for (const id of ["connectionRangeStart","connectionRangeEnd"]) {
      el(id).addEventListener("change",() =>
        stopMonitor("Monitoring stopped: selected range changed."));
    }
    el("connectionMonitorInterval").addEventListener("change",() => {
      stopMonitor("Monitoring stopped: refresh interval changed.");
      resetInterval();
    });
    resetInterval();
    // The existing Headless session is established asynchronously; no
    // authority is conferred or saved by the monitoring initialization.
    const initial = setInterval(() => {
      if (typeof token === "string" && token) {
        clearInterval(initial);
        load();
      }
    }, 450);
    document.addEventListener("visibilitychange",() => {
      if (document.hidden) stopMonitor("Monitoring stopped: tab not visible.");
    });
    window.addEventListener("pagehide",() => {
      stopMonitor();
      clearInterval(initial);
      if (timer) clearInterval(timer);
    }, {once:true});
  }
  document.addEventListener("DOMContentLoaded", init, {once:true});
})();
