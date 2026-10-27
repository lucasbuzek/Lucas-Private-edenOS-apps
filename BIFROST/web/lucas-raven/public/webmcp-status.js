"use strict";
/* Existing BIFROST Lucas Raven web application: OPTIONAL status-only WebMCP.
 * No ELYSIUM/RAVENsNEST/AppleRAVEN account federation, filesystem, shell,
 * local tokens, credentials, privileged operations or new device grants.
 */
(() => {
  async function readStatus() {
    try {
      const response = await fetch("/api/state", {
        method:"GET", credentials:"same-origin", cache:"no-store",
        headers:{accept:"application/json"}, redirect:"error"
      });
      if (response.status === 401 || response.status === 403) return {state:"authentication_required"};
      if (!response.ok || !(response.headers.get("content-type") || "").toLowerCase().includes("application/json")) return {state:"unavailable"};
      const data = await response.json();
      if (!data || !Array.isArray(data.nodes)) return {state:"unavailable"};
      return {state:"authenticated",devices_reported:data.nodes.length,
        devices_online:data.nodes.filter(n=>n && n.online===true).length};
    } catch { return {state:"unavailable"}; }
  }
  const button = document.getElementById("statusCheck");
  const output = document.getElementById("statusOutput");
  if (button && output) {
    button.addEventListener("click", async () => {
      button.disabled = true;
      output.textContent = "Checking authorized session…";
      const r = await readStatus();
      output.textContent = r.state === "authenticated"
        ? `Authorized session · ${r.devices_online} of ${r.devices_reported} reported nodes online.`
        : r.state === "authentication_required" ? "Sign in using the protected Raven portal first."
        : "Status unavailable; no device operation was attempted.";
      button.disabled = false;
    });
  }
  const context = document.modelContext;
  if (!context || typeof context.registerTool !== "function") return;
  context.registerTool({
    name:"raven_web_status",
    description:"Read redacted node online/offline counts for the currently authenticated Lucas Raven website. No file or device execution; no cross-account access.",
    inputSchema:{type:"object",properties:{},additionalProperties:false},
    annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false},
    execute:readStatus
  });
})();
