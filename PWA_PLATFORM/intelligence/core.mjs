const COST_CLASSES = new Set(['free-tier', 'local', 'user-connected']);

export class IntelligenceError extends Error {
  constructor(message, status = 400, code = 'INTELLIGENCE_REQUEST_INVALID') {
    super(message);
    this.name = 'IntelligenceError';
    this.status = status;
    this.code = code;
  }
}

/**
 * Create a provider-neutral intelligence router.
 * Authentication is performed by the hosting app/edge adapter before calling route().
 * App prompts and capabilities are registered server-side; callers cannot submit system prompts.
 */
export function createIntelligenceCore({ apps, providers, defaultProvider = 'workers-ai' }) {
  if (!apps || typeof apps !== 'object' || !providers || typeof providers !== 'object') {
    throw new TypeError('apps and providers registries are required');
  }
  const defaultAdapter = providers[defaultProvider];
  if (!defaultAdapter || !defaultAdapter.available || !['free-tier', 'local'].includes(defaultAdapter.costClass)) {
    throw new TypeError('default provider must be available and free-tier or local');
  }

  return Object.freeze({
    async route({ principal, appId, messages, providerId }) {
      if (!principal || typeof principal.id !== 'string' || !principal.id.trim()) {
        throw new IntelligenceError('Authentication required', 401, 'AUTH_REQUIRED');
      }
      if (!Array.isArray(principal.allowedApps) || !principal.allowedApps.includes(appId)) {
        throw new IntelligenceError('App access denied', 403, 'APP_ACCESS_DENIED');
      }
      const app = apps[appId];
      if (!app || typeof app.systemPrompt !== 'string' || !app.systemPrompt.trim()) {
        throw new IntelligenceError('App intelligence profile is not configured', 503, 'APP_PROFILE_UNAVAILABLE');
      }
      if (!Array.isArray(messages) || messages.length < 1 || messages.length > 24) {
        throw new IntelligenceError('Messages must contain 1–24 turns', 400, 'MESSAGE_COUNT_INVALID');
      }
      const clean = [];
      for (const item of messages) {
        if (!item || !['user', 'assistant'].includes(item.role) || typeof item.content !== 'string') {
          throw new IntelligenceError('Invalid message shape', 400, 'MESSAGE_INVALID');
        }
        const content = item.content.trim();
        if (!content || content.length > 8000) {
          throw new IntelligenceError('Message must contain 1–8000 characters', 400, 'MESSAGE_LENGTH_INVALID');
        }
        clean.push({ role: item.role, content });
      }
      if (clean.at(-1).role !== 'user') {
        throw new IntelligenceError('The last message must be from the user', 400, 'LAST_MESSAGE_INVALID');
      }

      const selectedId = providerId || defaultProvider;
      const provider = providers[selectedId];
      if (!provider || !COST_CLASSES.has(provider.costClass) || !provider.available) {
        // Explicitly do not silently reroute: provider choice can change cost, privacy or capability.
        throw new IntelligenceError('Selected intelligence provider is unavailable', 503, 'PROVIDER_UNAVAILABLE');
      }
      if (provider.costClass === 'user-connected' && providerId !== selectedId) {
        throw new IntelligenceError('User-connected providers require explicit selection', 403, 'PROVIDER_OPT_IN_REQUIRED');
      }
      if (typeof provider.generate !== 'function') {
        throw new IntelligenceError('Provider adapter is incomplete', 503, 'PROVIDER_ADAPTER_INVALID');
      }

      let response;
      try {
        response = await provider.generate({
          appId,
          userId: principal.id,
          systemPrompt: app.systemPrompt,
          messages: clean,
          tools: app.tools || [],
        });
      } catch {
        throw new IntelligenceError('Selected provider failed; no automatic provider switch was performed', 502, 'PROVIDER_FAILED');
      }
      if (typeof response !== 'string' || !response.trim()) {
        throw new IntelligenceError('Selected provider returned no usable response', 502, 'PROVIDER_EMPTY_RESPONSE');
      }
      return { appId, providerId: selectedId, response: response.trim() };
    },
  });
}
