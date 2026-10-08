// Lucas Raven edge API — BIFROST ZERO.
// Holds no provider credentials and can run nothing itself: it relays bounded,
// allowlisted capability actions to the BIFROST node, which validates again
// and executes. Two separate keys (stored as SHA-256 secrets):
//   operator — browser/iPhone: read state, request actions
//   node     — Mac bridge: publish state, claim actions, report results

const NODE_ONLINE_S = 90;
const QUEUE_TTL_MS = 120_000;
const CLAIM_TTL_MS = 600_000;
const MAX_BODY = 64 * 1024;
const NODE_RE = /^[a-z0-9][a-z0-9-]{1,40}$/;

// Mirrors bifrost/raven_bridge.py ACTIONS. Both sides validate.
const CATALOG = {
  "power.keepawake.start": {
    label: "Keep Mac awake", owner: "BIFROST (native caffeinate)",
    params: { minutes: { type: "int", min: 1, max: 480, default: 60 } },
  },
  "power.keepawake.stop": { label: "Release Keep Awake", owner: "BIFROST (native caffeinate)", params: {} },
  "bifrost.state.refresh": { label: "Refresh capability state", owner: "BIFROST", params: {} },
};

const json = (obj, status = 200) => new Response(JSON.stringify(obj), {
  status,
  headers: {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "x-content-type-options": "nosniff",
  },
});
const fail = (status, error) => json({ error }, status);

async function sha256Hex(s) {
  const d = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function keyMatches(request, expectedHex) {
  if (!expectedHex || expectedHex.length !== 64) return false;
  const m = (request.headers.get("authorization") || "").match(/^Bearer ([A-Za-z0-9]{32,128})$/);
  if (!m) return false;
  const got = new TextEncoder().encode(await sha256Hex(m[1]));
  const want = new TextEncoder().encode(expectedHex.toLowerCase());
  return got.byteLength === want.byteLength && crypto.subtle.timingSafeEqual(got, want);
}

async function body(request) {
  const len = Number(request.headers.get("content-length") || 0);
  if (len > MAX_BODY) throw new Error("body too large");
  const text = await request.text();
  if (text.length > MAX_BODY) throw new Error("body too large");
  const v = text ? JSON.parse(text) : {};
  if (!v || typeof v !== "object" || Array.isArray(v)) throw new Error("body must be an object");
  return v;
}

function validate(capability, params) {
  const spec = CATALOG[capability];
  if (!spec) return { error: "unknown capability" };
  if (params == null) params = {};
  if (typeof params !== "object" || Array.isArray(params)) return { error: "params must be an object" };
  const out = {};
  for (const k of Object.keys(params)) if (!(k in spec.params)) return { error: `unexpected parameter: ${k}` };
  for (const [k, p] of Object.entries(spec.params)) {
    const v = k in params ? params[k] : p.default;
    if (p.type === "int" && (!Number.isInteger(v) || v < p.min || v > p.max))
      return { error: `${k} must be an integer ${p.min}-${p.max}` };
    out[k] = v;
  }
  return { params: out };
}

function origin(request) {
  const ua = (request.headers.get("user-agent") || "").slice(0, 120);
  const cf = request.cf || {};
  return JSON.stringify({ ua, country: cf.country || null, colo: cf.colo || null });
}

function actionRow(r) {
  return {
    id: r.id, node_id: r.node_id, capability: r.capability, status: r.status,
    params: JSON.parse(r.params), origin: r.origin ? JSON.parse(r.origin) : null,
    created_at: r.created_at, claimed_at: r.claimed_at, completed_at: r.completed_at,
    result: r.result ? JSON.parse(r.result) : null,
  };
}

async function sweep(db, now) {
  await db.batch([
    db.prepare("UPDATE actions SET status='expired', completed_at=?1 WHERE status='queued' AND created_at < ?2")
      .bind(now, now - QUEUE_TTL_MS),
    db.prepare(`UPDATE actions SET status='failed', completed_at=?1,
                result='{"error":"node did not report a result in time"}'
                WHERE status='claimed' AND claimed_at < ?2`).bind(now, now - CLAIM_TTL_MS),
  ]);
}

// ------------------------------------------------------------------ node

async function nodeRoutes(path, request, db, now) {
  if (request.method !== "POST") return fail(405, "method not allowed");
  const b = await body(request);
  const nodeId = b.node_id;
  if (path === "node/state") {
    if (!NODE_RE.test(nodeId || "")) return fail(400, "invalid node_id");
    const meta = { bridge_version: String(b.bridge_version || "").slice(0, 40), hostname: String(b.hostname || "").slice(0, 80),
      actions: Array.isArray(b.actions) ? b.actions.filter((a) => a in CATALOG) : [] };
    await db.prepare(`INSERT INTO node_state(node_id, meta, state, updated_at) VALUES (?1, ?2, ?3, ?4)
                      ON CONFLICT(node_id) DO UPDATE SET meta=excluded.meta, state=excluded.state, updated_at=excluded.updated_at`)
      .bind(nodeId, JSON.stringify(meta), JSON.stringify(b.state || {}), now).run();
    return json({ ok: true });
  }
  if (path === "node/claim") {
    if (!NODE_RE.test(nodeId || "")) return fail(400, "invalid node_id");
    await sweep(db, now);
    const row = await db.prepare(`UPDATE actions SET status='claimed', claimed_at=?1
        WHERE id = (SELECT id FROM actions WHERE node_id=?2 AND status='queued' ORDER BY created_at LIMIT 1)
          AND status='queued'
        RETURNING id, capability, params, origin`).bind(now, nodeId).first();
    if (!row) return json({ action: null });
    return json({ action: { id: row.id, capability: row.capability, params: JSON.parse(row.params),
      origin: row.origin ? JSON.parse(row.origin) : null } });
  }
  if (path === "node/result") {
    if (typeof b.id !== "string" || b.id.length > 64) return fail(400, "invalid id");
    const res = JSON.stringify(b.result ?? null).slice(0, 8000);
    const r = await db.prepare(`UPDATE actions SET status=?1, completed_at=?2, result=?3
        WHERE id=?4 AND status='claimed'`).bind(b.ok ? "succeeded" : "failed", now, res, b.id).run();
    return r.meta.changes ? json({ ok: true }) : fail(409, "action not in claimed state");
  }
  return fail(404, "not found");
}

// -------------------------------------------------------------- operator

async function operatorRoutes(path, request, db, now) {
  if (path === "state" && request.method === "GET") {
    await sweep(db, now);
    const nodes = (await db.prepare("SELECT * FROM node_state ORDER BY updated_at DESC").all()).results;
    const actions = (await db.prepare("SELECT * FROM actions ORDER BY created_at DESC LIMIT 15").all()).results;
    return json({
      now, catalog: CATALOG,
      nodes: nodes.map((n) => ({
        node_id: n.node_id, meta: JSON.parse(n.meta), state: JSON.parse(n.state),
        updated_at: n.updated_at, age_s: Math.round((now - n.updated_at) / 1000),
        online: now - n.updated_at < NODE_ONLINE_S * 1000,
      })),
      actions: actions.map(actionRow),
    });
  }
  if (path === "actions" && request.method === "POST") {
    const b = await body(request);
    const nodeId = b.node_id || "lucas-macbook";
    if (!NODE_RE.test(nodeId)) return fail(400, "invalid node_id");
    const v = validate(b.capability, b.params);
    if (v.error) return fail(400, v.error);
    const node = await db.prepare("SELECT meta, updated_at FROM node_state WHERE node_id=?1").bind(nodeId).first();
    if (!node) return fail(404, "node not registered");
    if (!JSON.parse(node.meta).actions.includes(b.capability)) return fail(409, "node does not advertise this capability");
    const pending = await db.prepare("SELECT COUNT(*) AS n FROM actions WHERE node_id=?1 AND status IN ('queued','claimed')")
      .bind(nodeId).first();
    if (pending.n >= 5) return fail(429, "too many pending actions");
    const id = "act_" + crypto.randomUUID().replaceAll("-", "").slice(0, 20);
    await db.prepare(`INSERT INTO actions(id, node_id, capability, params, status, origin, created_at)
                      VALUES (?1, ?2, ?3, ?4, 'queued', ?5, ?6)`)
      .bind(id, nodeId, b.capability, JSON.stringify(v.params), origin(request), now).run();
    return json({ id, status: "queued", node_online: now - node.updated_at < NODE_ONLINE_S * 1000 }, 202);
  }
  const m = path.match(/^actions\/(act_[a-f0-9]{20})$/);
  if (m && request.method === "GET") {
    const r = await db.prepare("SELECT * FROM actions WHERE id=?1").bind(m[1]).first();
    return r ? json(actionRow(r)) : fail(404, "not found");
  }
  return fail(404, "not found");
}

export async function onRequest({ request, env, params }) {
  const path = (params.path || []).join("/");
  const now = Date.now();
  try {
    if (path === "health") return json({ ok: true, service: "lucas-raven", zero: "0.1.0" });
    if (path.startsWith("node/")) {
      if (!(await keyMatches(request, env.NODE_KEY_SHA256))) return fail(401, "unauthorized");
      return await nodeRoutes(path, request, env.DB, now);
    }
    if (!(await keyMatches(request, env.OPERATOR_KEY_SHA256))) return fail(401, "unauthorized");
    return await operatorRoutes(path, request, env.DB, now);
  } catch (e) {
    const msg = String(e && e.message || e);
    if (msg.includes("body") || e instanceof SyntaxError) return fail(400, msg.slice(0, 120));
    return fail(500, "internal error");
  }
}
