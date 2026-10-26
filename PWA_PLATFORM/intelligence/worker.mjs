const json = (body, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' },
});

/**
 * Create a same-origin edge endpoint around the shared core.
 * The host supplies an authentication adapter that validates a real session/token.
 * Never pass raw browser credentials to provider adapters or accept client system prompts.
 */
export function createIntelligenceWorker({ authenticate, core, maxBodyBytes = 128 * 1024 } = {}) {
  if (typeof authenticate !== 'function' || !core || typeof core.route !== 'function') {
    throw new TypeError('authenticate and core.route are required');
  }

  return {
    async fetch(request) {
      const url = new URL(request.url);
      if (url.pathname !== '/api/intelligence') return json({ error: 'Not found' }, 404);
      if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
      if (!request.headers.get('content-type')?.toLowerCase().includes('application/json')) {
        return json({ error: 'Content-Type must be application/json' }, 415);
      }
      const declared = Number(request.headers.get('content-length') || 0);
      if (declared > maxBodyBytes) return json({ error: 'Request too large' }, 413);

      let principal;
      try {
        principal = await authenticate(request);
      } catch {
        return json({ error: 'Authentication could not be verified' }, 401);
      }
      if (!principal || typeof principal.id !== 'string' || !principal.id.trim()) {
        return json({ error: 'Authentication required' }, 401);
      }

      let body;
      try {
        const raw = await request.text();
        if (new TextEncoder().encode(raw).byteLength > maxBodyBytes) return json({ error: 'Request too large' }, 413);
        body = JSON.parse(raw);
      } catch {
        return json({ error: 'Invalid JSON request' }, 400);
      }
      if (!body || typeof body !== 'object' || Array.isArray(body)) return json({ error: 'Invalid request shape' }, 400);

      try {
        const result = await core.route({
          principal,
          appId: body.appId,
          messages: body.messages,
          providerId: body.providerId,
        });
        return json(result);
      } catch (error) {
        const status = Number.isInteger(error?.status) && error.status >= 400 && error.status <= 599 ? error.status : 500;
        const code = typeof error?.code === 'string' ? error.code : 'INTELLIGENCE_UNAVAILABLE';
        const message = status >= 500 ? 'Intelligence service unavailable' : String(error.message || 'Request rejected');
        return json({ error: message, code }, status);
      }
    },
  };
}
