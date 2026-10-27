/* HISTORICAL RECOVERY SNAPSHOT; source from deployed raven-cloud-node, primary Cloudflare account, 2026-10-27. DO NOT DEPLOY AS APPLE RAVEN. Bound Worker source does not include credentials. */
var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// src/ai_provider.js
var PROVIDERS = /* @__PURE__ */ new Set(["groq", "workers-ai"]);
var MAX_PROMPT = 2e3;
var MAX_OUTPUT = 6900;
var TIMEOUT_MS = 25e3;
var POLICY = "Complete the user's requested text task using only the input given. Do not claim to have executed software, accessed devices, modified files, used tools, searched the internet, or submitted work unless those actions actually occurred. If the request requires external execution, explain that the result is an answer or plan only.";
function aiConfiguration(env) {
  const provider = String(env.RAVEN_AI_PROVIDER || "none");
  const model = String(env.RAVEN_AI_MODEL || "").trim();
  const configured = PROVIDERS.has(provider) && !!model && (provider === "workers-ai" ? !!env.AI : !!env.GROQ_API_KEY);
  return {
    provider: configured ? provider : "none",
    model: configured ? model : null,
    configured
  };
}
__name(aiConfiguration, "aiConfiguration");
function validateAIParams(params) {
  if (!params || typeof params !== "object" || Array.isArray(params)) return false;
  if (Object.keys(params).sort().join(",") !== "consent,prompt") return false;
  return typeof params.prompt === "string" && params.prompt.trim().length >= 1 && params.prompt.length <= MAX_PROMPT && params.consent === "send_to_cloud_provider";
}
__name(validateAIParams, "validateAIParams");
function modelText(data, provider) {
  const value = provider === "groq" ? data?.choices?.[0]?.message?.content : data?.response ?? data?.result?.response;
  if (typeof value !== "string" || !value.trim()) return null;
  return value.trim().slice(0, MAX_OUTPUT);
}
__name(modelText, "modelText");
async function performAI(env, params) {
  if (!validateAIParams(params)) {
    return { ok: false, result: { status: "REJECTED", error: "invalid or unconsented AI task" } };
  }
  const { provider, model, configured } = aiConfiguration(env);
  if (!configured) {
    return { ok: false, result: {
      status: "NOT_CONFIGURED",
      error: "Cloud AI provider and model not configured; Mac fallback is not automatic"
    } };
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    let data;
    const input = params.prompt.trim();
    if (provider === "workers-ai") {
      data = await env.AI.run(model, {
        messages: [{ role: "system", content: POLICY }, { role: "user", content: input }],
        max_tokens: 640
      }, { signal: controller.signal });
    } else {
      const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Bearer " + env.GROQ_API_KEY
        },
        body: JSON.stringify({
          model,
          temperature: 0.2,
          max_completion_tokens: 640,
          messages: [{ role: "system", content: POLICY }, { role: "user", content: input }]
        }),
        signal: controller.signal
      });
      if (!response.ok) {
        return { ok: false, result: {
          status: "PROVIDER_UNAVAILABLE",
          error: response.status === 429 ? "provider rate limit" : "provider rejected or could not complete the request"
        } };
      }
      data = await response.json();
    }
    const output = modelText(data, provider);
    if (!output) {
      return { ok: false, result: { status: "NO_OUTPUT", error: "provider returned no usable text" } };
    }
    return { ok: true, result: {
      status: "COMPLETED",
      provider,
      model,
      output,
      scope: "text-inference-only",
      deviceExecution: false
    } };
  } catch (err) {
    return { ok: false, result: {
      status: err?.name === "AbortError" ? "TIMED_OUT" : "PROVIDER_UNAVAILABLE",
      error: err?.name === "AbortError" ? "cloud AI request timed out" : "cloud AI provider unavailable"
    } };
  } finally {
    clearTimeout(timer);
  }
}
__name(performAI, "performAI");

// src/index.js
var NODE = "lucas-cloud";
var CLAIM_TTL_MS = 6e5;
var RESULT_RETENTION_MS = 7 * 24 * 60 * 60 * 1e3;
var ACTIONS = ["cloud.state.refresh", "github.repos.status", "ai.infer"];
var entry = /* @__PURE__ */ __name((status, summary, evidence = [], items) => ({
  status,
  summary,
  evidence,
  checked_at: Math.floor(Date.now() / 1e3),
  ...items ? { items } : {}
}), "entry");
function advertised(env) {
  return ACTIONS.filter((action) => action !== "ai.infer" || aiConfiguration(env).configured);
}
__name(advertised, "advertised");
function validate(cap, params) {
  if (cap === "ai.infer") return validateAIParams(params);
  return ACTIONS.includes(cap) && params && typeof params === "object" && !Array.isArray(params) && Object.keys(params).length === 0;
}
__name(validate, "validate");
async function github(env) {
  if (!env.GITHUB_TOKEN) {
    return { ok: false, result: {
      status: "NOT_CONFIGURED",
      error: "GITHUB_TOKEN is not configured"
    } };
  }
  const repos = String(env.GITHUB_REPOS || "").split(",").map((x) => x.trim()).filter((x) => /^[\w.-]+\/[\w.-]+$/.test(x)).slice(0, 50);
  const items = [];
  try {
    for (const repo of repos) {
      const headers = {
        authorization: "Bearer " + env.GITHUB_TOKEN,
        "user-agent": "raven-cloud-node",
        "x-github-api-version": "2022-11-28"
      };
      const [metadata, pulls] = await Promise.all([
        fetch("https://api.github.com/repos/" + repo, { headers }),
        fetch("https://api.github.com/repos/" + repo + "/pulls?state=open&per_page=1", { headers })
      ]);
      if (!metadata.ok || !pulls.ok) throw Error("upstream unavailable");
      const details = await metadata.json();
      const pullBody = await pulls.json();
      const pageCount = Number((pulls.headers.get("link") || "").match(/page=(\d+)>; rel="last"/)?.[1] || pullBody.length);
      items.push({
        repo,
        default_branch: String(details.default_branch || ""),
        pushed_at: String(details.pushed_at || ""),
        open_prs: pageCount
      });
    }
    return { ok: true, result: { status: "OBSERVED", items } };
  } catch {
    return { ok: false, result: { status: "ERROR", error: "GitHub unavailable" } };
  }
}
__name(github, "github");
async function publish(db, env, githubResult) {
  const now = Date.now();
  const ai = aiConfiguration(env);
  const state = { capabilities: {
    "github.repos": entry(
      githubResult?.status || "UNKNOWN",
      "Read-only repository status",
      [],
      githubResult?.items || []
    ),
    "cloud.node": entry("RUNNING", "Cloudflare cloud node cron reported execution"),
    "ai.infer": entry(
      ai.configured ? "AVAILABLE" : "NOT_CONFIGURED",
      ai.configured ? "Hosted AI provider configured; model-call health not yet proven" : "No cloud AI provider is configured; Mac is not a fallback",
      [],
      [{
        provider: ai.provider,
        model: ai.model,
        mode: "text-inference-only",
        machineRequired: false
      }]
    )
  } };
  await db.prepare(
    "INSERT INTO node_state(node_id,meta,state,updated_at) VALUES(?1,?2,?3,?4) ON CONFLICT(node_id) DO UPDATE SET meta=excluded.meta,state=excluded.state,updated_at=excluded.updated_at"
  ).bind(NODE, JSON.stringify({
    hostname: "Cloudflare",
    actions: advertised(env)
  }), JSON.stringify(state), now).run();
}
__name(publish, "publish");
async function tick(env) {
  await publish(env.DB, env);
  const now = Date.now();
  await env.DB.prepare(
    `UPDATE actions SET status='expired',completed_at=?1,result='{"status":"EXPIRED"}',params='{"redacted":true}' WHERE node_id=?2 AND capability='ai.infer' AND status='queued' AND created_at<?3`
  ).bind(now, NODE, now - 12e4).run();
  await env.DB.prepare(
    `UPDATE actions SET status='failed',completed_at=?1,result='{"status":"CLAIM_TIMEOUT"}',params=CASE WHEN capability='ai.infer' THEN '{"redacted":true}' ELSE params END WHERE node_id=?2 AND status='claimed' AND claimed_at<?3`
  ).bind(now, NODE, now - CLAIM_TTL_MS).run();
  await env.DB.prepare(
    "UPDATE actions SET result=NULL WHERE node_id=?1 AND capability='ai.infer' AND status IN ('succeeded','failed','expired') AND completed_at<?2"
  ).bind(NODE, now - RESULT_RETENTION_MS).run();
  const action = await env.DB.prepare(
    "UPDATE actions SET status='claimed',claimed_at=?1 WHERE id=(SELECT id FROM actions WHERE node_id=?2 AND status='queued' ORDER BY created_at LIMIT 1) AND status='queued' RETURNING id,capability,params"
  ).bind(now, NODE).first();
  if (!action) return;
  let params;
  try {
    params = JSON.parse(action.params);
  } catch {
    params = null;
  }
  let outcome;
  if (!validate(action.capability, params)) {
    outcome = { ok: false, result: {
      status: "REJECTED",
      error: "invalid cloud action"
    } };
  } else if (action.capability === "ai.infer") {
    outcome = await performAI(env, params);
  } else if (action.capability === "github.repos.status") {
    outcome = await github(env);
  } else {
    await publish(env.DB, env);
    outcome = { ok: true, result: { status: "OBSERVED" } };
  }
  const result = JSON.stringify(outcome.result).slice(0, 8e3);
  await env.DB.prepare(
    `UPDATE actions SET status=?1,completed_at=?2,result=?3, params=CASE WHEN capability='ai.infer' THEN '{"redacted":true}' ELSE params END WHERE id=?4 AND node_id=?5 AND status='claimed'`
  ).bind(
    outcome.ok ? "succeeded" : "failed",
    Date.now(),
    result,
    action.id,
    NODE
  ).run();
  if (action.capability === "github.repos.status") {
    await publish(env.DB, env, outcome.result);
  }
}
__name(tick, "tick");
var index_default = {
  scheduled(_controller, env, ctx) {
    ctx.waitUntil(tick(env));
  },
  fetch() {
    return new Response("method not allowed", { status: 405 });
  }
};
export {
  index_default as default,
  tick,
  validate
};
//# sourceMappingURL=index.js.map
