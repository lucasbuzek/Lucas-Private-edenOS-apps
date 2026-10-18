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
export function createIntelligenceCore({ apps, providers, defaultProvider = null }) {
  if (!apps || typeof apps !== 'object' || !providers || typeof providers !== 'object') {
    throw new TypeError('apps and providers registries are required');
  }
  if (defaultProvider !== null) {
    throw new TypeError('automatic default AI providers are forbidden; each app must explicitly select a verified capable provider');
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

      if (typeof providerId !== 'string' || !providerId) {
        throw new IntelligenceError('Choose an authorized capable intelligence provider', 409, 'PROVIDER_SELECTION_REQUIRED');
      }
      const selectedId = providerId;
      if (Array.isArray(app.allowedProviders) && !app.allowedProviders.includes(selectedId)) {
        throw new IntelligenceError('Provider is not permitted for this app', 403, 'PROVIDER_NOT_PERMITTED_FOR_APP');
      }
      const provider = providers[selectedId];
      if (!provider || !COST_CLASSES.has(provider.costClass) || !provider.available) {
        // Explicitly do not silently reroute: provider choice can change cost, privacy or capability.
        throw new IntelligenceError('Selected intelligence provider is unavailable', 503, 'PROVIDER_UNAVAILABLE');
      }
      if (provider.costClass === 'user-connected' &&
          (!Array.isArray(principal.allowedProviders) || !principal.allowedProviders.includes(selectedId))) {
        throw new IntelligenceError('User-connected provider was not authorized for this account', 403, 'PROVIDER_OPT_IN_REQUIRED');
      }
      const required = Array.isArray(app.requiredCapabilities) ? app.requiredCapabilities : [];
      const verified = Array.isArray(provider.verifiedCapabilities) ? provider.verifiedCapabilities : [];
      if (!required.every(capability => verified.includes(capability))) {
        throw new IntelligenceError('Selected provider has not passed this application capability gate', 409, 'PROVIDER_CAPABILITY_UNVERIFIED');
      }
      if (required.length) {
        const acceptance=provider.acceptedFor?.[appId];
        if (acceptance?.status !== 'ACCEPTED' ||
            !Array.isArray(acceptance.capabilities) ||
            !required.every(capability=>acceptance.capabilities.includes(capability))) {
          throw new IntelligenceError('Live app-specific model acceptance has not been recorded', 409, 'PROVIDER_LIVE_ACCEPTANCE_REQUIRED');
        }
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
