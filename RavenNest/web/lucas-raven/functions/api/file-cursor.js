// RAVENsNEST selected-source pagination: tamper-evident, user/source/path-bound cursors.
const MAX_BYTES = 6000;
const textEncoder = new TextEncoder();
const b64url = bytes => btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
function unb64url(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]+$/.test(value)) throw Error('invalid cursor');
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
  return Uint8Array.from(atob(normalized + '='.repeat((4 - normalized.length % 4) % 4)), c => c.charCodeAt(0));
}
async function keyFor(env) {
  const secret = env.RAVEN_FILES_CURSOR_KEY;
  if (typeof secret !== 'string' || secret.length < 32) throw Error('cursor service not configured');
  return crypto.subtle.importKey('raw', textEncoder.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign', 'verify']);
}
export async function sealCursor(env, scope, providerToken, now = Date.now()) {
  if (typeof providerToken !== 'string' || !providerToken || providerToken.length > 2500) throw Error('invalid cursor');
  const payload = textEncoder.encode(JSON.stringify({ version: 1, user: scope.user, source: scope.source, path: scope.path, provider: scope.provider, token: providerToken, expires: now + 15 * 60 * 1000 }));
  if (payload.length > MAX_BYTES) throw Error('invalid cursor');
  const signature = await crypto.subtle.sign('HMAC', await keyFor(env), payload);
  return b64url(payload) + '.' + b64url(new Uint8Array(signature));
}
export async function openCursor(env, scope, cursor, now = Date.now()) {
  if (typeof cursor !== 'string' || cursor.length > 9000) throw Error('invalid cursor');
  const parts = cursor.split('.');
  if (parts.length !== 2) throw Error('invalid cursor');
  const payload = unb64url(parts[0]), signature = unb64url(parts[1]);
  if (payload.length > MAX_BYTES || signature.length !== 32) throw Error('invalid cursor');
  if (!await crypto.subtle.verify('HMAC', await keyFor(env), signature, payload)) throw Error('invalid cursor');
  let data;
  try { data = JSON.parse(new TextDecoder().decode(payload)); } catch { throw Error('invalid cursor'); }
  if (data.version !== 1 || data.user !== scope.user || data.source !== scope.source || data.path !== scope.path || data.provider !== scope.provider || typeof data.token !== 'string' || !data.token || data.token.length > 2500 || !Number.isFinite(data.expires) || data.expires <= now || data.expires > now + 16 * 60 * 1000) throw Error('invalid cursor');
  return data.token;
}
