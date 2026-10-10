/**
 * RavenNest cloud-side AI inference provider.
 * The Cloudflare Worker routes bounded text requests to a hosted AI provider.
 * The Mac is not part of this execution path, and the model has NO device,
 * repository, filesystem or shell tools.
 *
 * Provider, model, keys, max tokens and cost policy are server configuration.
 * A browser never chooses an arbitrary URL or passes a provider credential.
 */
const PROVIDERS = new Set(["groq", "workers-ai"]);
const MAX_PROMPT = 2000;
const MAX_OUTPUT = 6900;
const TIMEOUT_MS = 25000;
const POLICY = "Complete the user's requested text task using only the input given. " +
  "Do not claim to have executed software, accessed devices, modified files, " +
  "used tools, searched the internet, or submitted work unless those actions actually occurred. " +
  "If the request requires external execution, explain that the result is an answer or plan only.";

export function aiConfiguration(env) {
  const provider = String(env.RAVEN_AI_PROVIDER || "none");
  const model = String(env.RAVEN_AI_MODEL || "").trim();
  const configured = PROVIDERS.has(provider) && !!model &&
    (provider === "workers-ai" ? !!env.AI : !!env.GROQ_API_KEY);
  return {
    provider: configured ? provider : "none",
    model: configured ? model : null,
    configured,
  };
}

export function validateAIParams(params) {
  if (!params || typeof params !== "object" || Array.isArray(params)) return false;
  if (Object.keys(params).sort().join(",") !== "consent,prompt") return false;
  return typeof params.prompt === "string" &&
    params.prompt.trim().length >= 1 &&
    params.prompt.length <= MAX_PROMPT &&
    params.consent === "send_to_cloud_provider";
}

function modelText(data, provider) {
  const value = provider === "groq" ?
    data?.choices?.[0]?.message?.content :
    (data?.response ?? data?.result?.response);
  if (typeof value !== "string" || !value.trim()) return null;
  return value.trim().slice(0, MAX_OUTPUT);
}

export async function performAI(env, params) {
  if (!validateAIParams(params)) {
    return {ok:false, result:{status:"REJECTED", error:"invalid or unconsented AI task"}};
  }
  const {provider,model,configured} = aiConfiguration(env);
  if (!configured) {
    return {ok:false, result:{status:"NOT_CONFIGURED",
      error:"Cloud AI provider and model not configured; Mac fallback is not automatic"}};
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    let data;
    const input = params.prompt.trim();
    if (provider === "workers-ai") {
      data = await env.AI.run(model, {
        messages: [{role:"system", content:POLICY}, {role:"user", content:input}],
        max_tokens: 640,
      }, {signal:controller.signal});
    } else {
      const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method:"POST",
        headers: {
          "content-type":"application/json",
          authorization:"Bearer " + env.GROQ_API_KEY,
        },
        body:JSON.stringify({
          model,
          temperature:0.2,
          max_completion_tokens:640,
          messages:[{role:"system",content:POLICY},{role:"user",content:input}],
        }),
        signal:controller.signal,
      });
      if (!response.ok) {
        return {ok:false,result:{
          status:"PROVIDER_UNAVAILABLE",
          error:response.status === 429 ? "provider rate limit" :
            "provider rejected or could not complete the request",
        }};
      }
      data = await response.json();
    }
    const output = modelText(data, provider);
    if (!output) {
      return {ok:false,result:{status:"NO_OUTPUT", error:"provider returned no usable text"}};
    }
    return {ok:true,result:{
      status:"COMPLETED", provider, model, output,
      scope:"text-inference-only", deviceExecution:false,
    }};
  } catch (err) {
    return {ok:false,result:{
      status:err?.name === "AbortError" ? "TIMED_OUT" : "PROVIDER_UNAVAILABLE",
      error:err?.name === "AbortError" ? "cloud AI request timed out" :
        "cloud AI provider unavailable",
    }};
  } finally {
    clearTimeout(timer);
  }
}
