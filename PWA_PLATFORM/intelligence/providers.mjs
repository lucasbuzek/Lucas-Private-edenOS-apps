/** Server-side adapters. Keep API credentials in host secret stores, never in browser bundles. */

export function workersAIAdapter({ binding, model = '@cf/meta/llama-3.3-70b-instruct-fp8-fast' } = {}) {
  return {
    id: 'workers-ai',
    costClass: 'free-tier',
    get available() { return Boolean(binding && typeof binding.run === 'function' && model); },
    async generate({ systemPrompt, messages }) {
      if (!this.available) throw new Error('Workers AI binding/model unavailable');
      const result = await binding.run(model, {
        messages: [{ role: 'system', content: systemPrompt }, ...messages],
        max_tokens: 2048,
        temperature: 0.3,
      });
      return result?.response ?? '';
    },
  };
}

export function geminiFreeTierAdapter({ apiKey, model = 'gemini-2.5-flash', fetchImpl = fetch } = {}) {
  return {
    id: 'gemini-free-tier',
    costClass: 'free-tier',
    get available() { return Boolean(apiKey && model && typeof fetchImpl === 'function'); },
    async generate({ systemPrompt, messages }) {
      if (!this.available) throw new Error('Gemini free-tier adapter is not configured');
      const response = await fetchImpl(
        `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
        {
          method: 'POST',
          headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: systemPrompt }] },
            contents: messages.map(message => ({
              role: message.role === 'assistant' ? 'model' : 'user',
              parts: [{ text: message.content }],
            })),
            generationConfig: { temperature: 0.3, maxOutputTokens: 2048 },
          }),
        },
      );
      if (!response.ok) throw new Error(`Gemini returned HTTP ${response.status}`);
      const data = await response.json();
      return data.candidates?.[0]?.content?.parts?.map(part => part.text || '').join('') ?? '';
    },
  };
}
