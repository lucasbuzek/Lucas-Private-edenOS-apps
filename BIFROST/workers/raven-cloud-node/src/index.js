import {aiConfiguration, validateAIParams, performAI} from "./ai_provider.js";

/**
 * Raven cloud worker: provider-side execution never routes through the Mac.
 * Cron consumes only allowlisted lucas-cloud queue items from D1.
 *
 * Cloud AI is text inference ONLY; never advertises Codex execution, shell,
 * filesystem, or a completed build. All credentials live in Worker secrets.
 * User grants and origin authorization are enforced by the Raven edge.
 */
const NODE = "lucas-cloud";
const CLAIM_TTL_MS = 600_000;
const RESULT_RETENTION_MS = 7 * 24 * 60 * 60 * 1000;
const ACTIONS = ["cloud.state.refresh", "github.repos.status", "ai.infer"];

const entry = (status, summary, evidence = [], items) => ({
  status, summary, evidence, checked_at: Math.floor(Date.now() / 1000),
  ...(items ? {items} : {}),
});

function advertised(env) {
  return ACTIONS.filter(action => action !== "ai.infer" || aiConfiguration(env).configured);
}

export function validate(cap, params) {
  if (cap === "ai.infer") return validateAIParams(params);
  return ACTIONS.includes(cap) && params && typeof params === "object" &&
    !Array.isArray(params) && Object.keys(params).length === 0;
}

async function github(env) {
  if (!env.GITHUB_TOKEN) {
    return {ok:false,result:{
      status:"NOT_CONFIGURED", error:"GITHUB_TOKEN is not configured",
    }};
  }
  const repos = String(env.GITHUB_REPOS || "")
    .split(",").map(x => x.trim())
    .filter(x => /^[\w.-]+\/[\w.-]+$/.test(x)).slice(0, 50);
  const items = [];
  try {
    for (const repo of repos) {
      const headers = {
        authorization:"Bearer " + env.GITHUB_TOKEN,
        "user-agent":"raven-cloud-node",
        "x-github-api-version":"2022-11-28",
      };
      const [metadata, pulls] = await Promise.all([
        fetch("https://api.github.com/repos/" + repo, {headers}),
        fetch("https://api.github.com/repos/" + repo +
          "/pulls?state=open&per_page=1", {headers}),
      ]);
      if (!metadata.ok || !pulls.ok) throw Error("upstream unavailable");
      const details = await metadata.json();
      const pullBody = await pulls.json();
      const pageCount = Number((pulls.headers.get("link") || "")
        .match(/page=(\d+)>; rel="last"/)?.[1] || pullBody.length);
      items.push({
        repo,
        default_branch:String(details.default_branch || ""),
        pushed_at:String(details.pushed_at || ""),
        open_prs:pageCount,
      });
    }
    return {ok:true,result:{status:"OBSERVED",items}};
  } catch {
    return {ok:false,result:{status:"ERROR",error:"GitHub unavailable"}};
  }
}

async function publish(db, env, githubResult) {
  const now = Date.now();
  const ai = aiConfiguration(env);
  const state = {capabilities:{
    "github.repos":entry(githubResult?.status || "UNKNOWN",
      "Read-only repository status", [], githubResult?.items || []),
    "cloud.node":entry("RUNNING","Cloudflare cloud node cron reported execution"),
    "ai.infer":entry(ai.configured ? "AVAILABLE" : "NOT_CONFIGURED",
      ai.configured ?
        "Hosted AI provider configured; model-call health not yet proven" :
        "No cloud AI provider is configured; Mac is not a fallback",
      [], [{
        provider:ai.provider,
        model:ai.model,
        mode:"text-inference-only",
        machineRequired:false,
      }]),
  }};
  await db.prepare(
    "INSERT INTO node_state(node_id,meta,state,updated_at) " +
    "VALUES(?1,?2,?3,?4) ON CONFLICT(node_id) DO UPDATE SET " +
    "meta=excluded.meta,state=excluded.state,updated_at=excluded.updated_at"
  ).bind(NODE, JSON.stringify({
    hostname:"Cloudflare",
    actions:advertised(env),
  }), JSON.stringify(state), now).run();
}

export async function tick(env) {
  await publish(env.DB, env);
  const now = Date.now();
  // Queue expiry must be enforced even when no human reads the edge state.
  // Otherwise stale prompts can linger or execute after their authorization window.
  await env.DB.prepare(
    "UPDATE actions SET status='expired',completed_at=?1," +
    "result='{\"status\":\"EXPIRED\"}',params='{\"redacted\":true}' " +
    "WHERE node_id=?2 AND capability='ai.infer' AND status='queued' AND created_at<?3"
  ).bind(now,NODE,now-120000).run();
  // Recover abandoned claims without relying on someone opening Raven's UI.
  // Never automatically retry a potentially completed external operation.
  await env.DB.prepare(
    "UPDATE actions SET status='failed',completed_at=?1," +
    "result='{\"status\":\"CLAIM_TIMEOUT\"}'," +
    "params=CASE WHEN capability='ai.infer' THEN '{\"redacted\":true}' " +
    "ELSE params END WHERE node_id=?2 AND status='claimed' AND claimed_at<?3"
  ).bind(now,NODE,now-CLAIM_TTL_MS).run();
  // Cloud AI outputs are temporary. Retain job metadata, not text forever.
  await env.DB.prepare(
    "UPDATE actions SET result=NULL WHERE node_id=?1 AND capability='ai.infer' " +
    "AND status IN ('succeeded','failed','expired') AND completed_at<?2"
  ).bind(NODE,now-RESULT_RETENTION_MS).run();
  const action = await env.DB.prepare(
    "UPDATE actions SET status='claimed',claimed_at=?1 " +
    "WHERE id=(SELECT id FROM actions WHERE node_id=?2 AND status='queued' " +
    "ORDER BY created_at LIMIT 1) AND status='queued' " +
    "RETURNING id,capability,params"
  ).bind(now,NODE).first();
  if (!action) return;
  let params;
  try { params = JSON.parse(action.params); } catch { params = null; }
  let outcome;
  if (!validate(action.capability,params)) {
    outcome = {ok:false,result:{
      status:"REJECTED",error:"invalid cloud action",
    }};
  } else if (action.capability === "ai.infer") {
    outcome = await performAI(env,params);
  } else if (action.capability === "github.repos.status") {
    outcome = await github(env);
  } else {
    await publish(env.DB,env);
    outcome = {ok:true,result:{status:"OBSERVED"}};
  }
  const result = JSON.stringify(outcome.result).slice(0,8000);
  // Do not preserve cloud prompts in completed D1 action params.
  // Queued/expired prompts have a separate short TTL and scrub gate.
  await env.DB.prepare(
    "UPDATE actions SET status=?1,completed_at=?2,result=?3, " +
    "params=CASE WHEN capability='ai.infer' THEN '{\"redacted\":true}' " +
    "ELSE params END WHERE id=?4 AND node_id=?5 AND status='claimed'"
  ).bind(outcome.ok ? "succeeded" : "failed",
    Date.now(),result,action.id,NODE).run();
  if (action.capability === "github.repos.status") {
    await publish(env.DB,env,outcome.result);
  }
}

export default {
  scheduled(_controller, env, ctx) {ctx.waitUntil(tick(env));},
  fetch() {return new Response("method not allowed",{status:405});},
};
