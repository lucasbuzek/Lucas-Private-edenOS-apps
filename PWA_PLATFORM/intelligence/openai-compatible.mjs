/**
 * A server-side OpenAI-compatible chat adapter for explicitly connected providers.
 * Works with Ollama, LM Studio or provider-owned compatible endpoints, depending
 * on runtime reachability and authorization. No provider is auto-enabled.
 * Never allow a browser caller to provide endpoint, API key or model.
 */
function completionUrl(endpoint, costClass) {
  if (typeof endpoint !== 'string') return null;
  try {
    const url = new URL(endpoint);
    const local = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
    if (url.username || url.password || url.search || url.hash) return null;
    if (url.protocol !== 'https:' && !(costClass === 'local' && url.protocol === 'http:' && local)) return null;
    if (!/^\/v1\/?$/.test(url.pathname)) return null;
    url.pathname = '/v1/chat/completions';
    return url.toString();
  } catch { return null; }
}

export function openAICompatibleAdapter({
  endpoint, model, apiKey, costClass = 'user-connected',
  verifiedCapabilities = [], fetchImpl = globalThis.fetch,
} = {}) {
  if (!['local', 'user-connected', 'free-tier'].includes(costClass)) {
    throw new TypeError('Unsupported OpenAI-compatible cost classification');
  }
  const requestUrl = completionUrl(endpoint, costClass);
  if (!Array.isArray(verifiedCapabilities) || verifiedCapabilities.some(x => typeof x !== 'string')) {
    throw new TypeError('Verified capabilities must be a string list');
  }
  return Object.freeze({
    id: 'openai-compatible',
    costClass,
    verifiedCapabilities: Object.freeze([...verifiedCapabilities]),
    get available() {
      return Boolean(requestUrl && typeof model === 'string' && model.trim() && typeof fetchImpl === 'function');
    },
    async generate({ systemPrompt, messages }) {
      if (!this.available) throw new Error('OpenAI-compatible provider is not configured');
      const headers = { 'content-type': 'application/json' };
      if (apiKey) headers.authorization = 'Bearer ' + apiKey;
      const response = await fetchImpl(requestUrl, {
        method: 'POST', headers, redirect: 'error',
        signal: AbortSignal.timeout(45000),
        body: JSON.stringify({
          model,
          messages: [{ role: 'system', content: systemPrompt }, ...messages],
          stream: false,
          temperature: 0.25,
          max_tokens: 2048,
        }),
      });
      if (!response.ok) throw new Error('Configured provider returned HTTP ' + response.status);
      const result = await response.json();
      const answer = result?.choices?.[0]?.message?.content;
      if (typeof answer !== 'string' || !answer.trim()) throw new Error('Configured provider returned no text');
      return answer;
    },
  });
}
