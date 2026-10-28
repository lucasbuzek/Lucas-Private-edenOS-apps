// One function, three possible model backends. Default is free Workers AI.

export async function generate(env, system, history) {
  const provider = (env.PROVIDER || 'workers-ai').toLowerCase();
  if (provider === 'gemini') return gemini(env, system, history);
  if (provider === 'anthropic') return anthropic(env, system, history);
  if (provider === 'openai') return openai(env, system, history);
  if (provider === 'mistral') return mistral(env, system, history);
  return workersAi(env, system, history);
}

async function workersAi(env, system, history) {
  const out = await env.AI.run(env.WORKERS_AI_MODEL, {
    messages: [{ role: 'system', content: system }, ...history],
    max_tokens: 1500,
    temperature: 0.3,
  });
  return out.response ?? '';
}

async function gemini(env, system, history) {
  if (!env.GEMINI_API_KEY) throw new Error('GEMINI_API_KEY is not set');
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${env.GEMINI_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: history.map((m) => ({
          role: m.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: m.content }],
        })),
        generationConfig: { temperature: 0.3, maxOutputTokens: 2048 },
      }),
    }
  );
  if (!res.ok) throw new Error(`Gemini error ${res.status}`);
  const data = await res.json();
  return data.candidates?.[0]?.content?.parts?.map((p) => p.text).join('') ?? '';
}

async function anthropic(env, system, history) {
  if (!env.ANTHROPIC_API_KEY) throw new Error('ANTHROPIC_API_KEY is not set');
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: env.ANTHROPIC_MODEL,
      max_tokens: 2048,
      system: [{ type: 'text', text: system, cache_control: { type: 'ephemeral' } }],
      messages: history,
    }),
  });
  if (!res.ok) throw new Error(`Anthropic error ${res.status}`);
  const data = await res.json();
  return data.content?.filter((b) => b.type === 'text').map((b) => b.text).join('') ?? '';
}

/* Additional CRESUS Alpha adapters. Never read tokens from browser localStorage,
   never infer that a consumer ChatGPT/Mistral session authorizes API calls. */
async function openai(env, system, history) {
  if (!env.OPENAI_API_KEY || !env.OPENAI_MODEL) throw new Error('OpenAI provider is not connected');
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method:'POST',
    headers:{'content-type':'application/json','authorization':'Bearer ' + env.OPENAI_API_KEY},
    body:JSON.stringify({
      model:env.OPENAI_MODEL, messages:[{role:'system',content:system},...history],
      max_completion_tokens:2048
    })
  });
  if(!response.ok) throw new Error('OpenAI provider request failed: HTTP ' + response.status);
  const data=await response.json();
  return typeof data.choices?.[0]?.message?.content === 'string' ? data.choices[0].message.content : '';
}

async function mistral(env, system, history) {
  if (!env.MISTRAL_API_KEY || !env.MISTRAL_MODEL) throw new Error('Mistral provider is not connected');
  const response = await fetch('https://api.mistral.ai/v1/chat/completions',{
    method:'POST',
    headers:{'content-type':'application/json','authorization':'Bearer ' + env.MISTRAL_API_KEY},
    body:JSON.stringify({
      model:env.MISTRAL_MODEL, messages:[{role:'system',content:system},...history],
      max_tokens:2048,temperature:0.3
    })
  });
  if(!response.ok) throw new Error('Mistral provider request failed: HTTP ' + response.status);
  const data=await response.json();
  return typeof data.choices?.[0]?.message?.content === 'string' ? data.choices[0].message.content : '';
}
