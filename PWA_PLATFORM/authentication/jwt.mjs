import { createRemoteJWKSet, jwtVerify } from 'jose';

/**
 * Provider adapters verify signed JWTs and then consult a deployment-specific
 * membership/permission resolver. Neither a JWT email nor a browser appId alone
 * grants access. Cross-app sessions or memberships are never inferred.
 */
function tokenFromAccess(request) {
  const assertion = request.headers.get('cf-access-jwt-assertion');
  if (assertion) return assertion;
  const cookie = request.headers.get('cookie') || '';
  return cookie.match(/(?:^|;\s*)CF_Authorization=([^;]+)/)?.[1] || null;
}

function tokenFromBearer(request) {
  const header = request.headers.get('authorization') || '';
  const matched = /^Bearer ([A-Za-z0-9._~-]+)$/i.exec(header);
  return matched?.[1] || null;
}

function prepare({ appId, authorize, issuer, audience, jwksUrl, jwks, algorithms, requireClaims, tokenFrom, claimCheck }) {
  if (typeof appId !== 'string' || !appId.trim()) throw new TypeError('An exact hosted app ID is required');
  if (typeof authorize !== 'function') throw new TypeError('App-specific membership authorizer is required');
  if (typeof audience !== 'string' || !audience.trim()) throw new TypeError('An exact JWT audience is required');
  const resolver = jwks || createRemoteJWKSet(new URL(jwksUrl));
  return async (request) => {
    const token = tokenFrom(request);
    if (!token || token.length > 8192 || token.split('.').length !== 3) return null;
    try {
      const { payload } = await jwtVerify(token, resolver, {
        issuer, audience, algorithms,
        requiredClaims: requireClaims,
      });
      if (!claimCheck(payload)) return null;
      const subject = String(payload.sub);
      const email = typeof payload.email === 'string' ? payload.email.toLowerCase() : null;
      const membership = await authorize({ appId, userId: subject, email });
      if (!membership || membership.allowed !== true) return null;
      return {
        id: subject, email,
        allowedApps: [appId],
        allowedProviders: Array.isArray(membership.allowedProviders)
          ? membership.allowedProviders.filter(value => typeof value === 'string') : [],
      };
    } catch { return null; }
  };
}

export function createCloudflareAccessAuthenticator({ appId, teamDomain, audience, authorize, jwks } = {}) {
  if (typeof teamDomain !== 'string' ||
      !/^[a-z0-9-]+\.cloudflareaccess\.com$/i.test(teamDomain)) {
    throw new TypeError('A verified Cloudflare Access team domain is required');
  }
  const origin = 'https://' + teamDomain.toLowerCase();
  return prepare({
    appId, authorize, issuer: origin, audience,
    jwksUrl: origin + '/cdn-cgi/access/certs', jwks,
    algorithms: ['RS256'],
    requireClaims: ['exp', 'iat', 'nbf', 'iss', 'aud', 'sub'],
    tokenFrom: tokenFromAccess,
    claimCheck: payload => payload.type === 'app' &&
      typeof payload.sub === 'string' && payload.sub.trim().length > 0 &&
      typeof payload.email === 'string' && payload.email.includes('@'),
  });
}

export function createSupabaseAuthenticator({ appId, projectUrl, audience = 'authenticated', authorize, jwks } = {}) {
  let base;
  try {
    base = new URL(projectUrl);
  } catch { throw new TypeError('A verified Supabase project HTTPS URL is required'); }
  if (base.protocol !== 'https:' || base.username || base.password ||
      base.search || base.hash || base.pathname !== '/' || !base.hostname) {
    throw new TypeError('A verified Supabase project HTTPS URL is required');
  }
  const issuer = base.origin + '/auth/v1';
  return prepare({
    appId, authorize, issuer, audience,
    jwksUrl: issuer + '/.well-known/jwks.json', jwks,
    // Legacy HS256 tokens are intentionally not supported without server-side getUser verification.
    algorithms: ['RS256', 'ES256', 'EdDSA'],
    requireClaims: ['exp', 'iat', 'iss', 'aud', 'sub'],
    tokenFrom: tokenFromBearer,
    claimCheck: payload => payload.role === 'authenticated' &&
      typeof payload.sub === 'string' && payload.sub.trim().length > 0,
  });
}
