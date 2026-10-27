/**
 * AppleRAVEN — private Cloudflare account provisioning shell.
 *
 * Deliberately CLOSED until existing Raven API plus OAuth 2.1 authorization
 * is integrated and an actual Apple device is paired.
 * Reuses source lineage in BIFROST/web/lucas-raven; NOT a replacement.
 * Production Raven Workers, historical accounts and identity grants untouched.
 */
const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
  "x-content-type-options": "nosniff",
  "content-security-policy": "default-src 'none'",
};
const response = (body, status) => new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
export default {
  async fetch(request, env) {
    const pathname = new URL(request.url).pathname;
    if (request.method === "GET" && pathname === "/health") {
      try {
        const db = await env.DB.prepare("SELECT 1 AS ready").first();
        if (db?.ready !== 1) throw new Error("D1 not ready");
      } catch {
        return response({ service: "AppleRAVEN", status: "database_unavailable" }, 503);
      }
      return response({
        service: "AppleRAVEN",
        environment: "ravensnest",
        stage: "account_provisioned",
        transport: "mcp_locked",
        protocol_target: "2026-07-28",
        identity: "not_configured",
        mac_agent: "not_paired",
      }, 200);
    }
    if (pathname === "/mcp" || pathname === "/api/mcp" || pathname.startsWith("/api/")) {
      return response({ error: "authorization_not_configured", service: "AppleRAVEN" }, 503);
    }
    return response({ error: "not_found" }, 404);
  },
};
