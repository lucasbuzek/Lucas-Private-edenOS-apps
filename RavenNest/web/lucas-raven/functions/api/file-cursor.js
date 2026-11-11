// Confidential, authenticated, source/folder/user-bound provider pagination cursors.
// Keep provider continuation tokens out of browser URLs, history and logs.
// Candidate v2 intentionally invalidates older signed-but-readable v1 cursors.
const MAX_BYTES = 6000;
const encoder = new TextEncoder();
const b64url = bytes => btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
function unb64url(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]+$/.test(value)) throw Error('invalid cursor');
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
  return Uint8Array.from(atob(normalized + '='.repeat((4 - normalized.length % 4) % 4)), c => c.charCodeAt(0));
}
async function keyFor(env) {
  const secret = env.RAVEN_FILES_CURSOR_KEY;
  if (typeof secret !== 'string' || secret.length < 32) throw Error('cursor service not configured');
  // Domain separation avoids using the raw secret directly as an AES key.
  const material = await crypto.subtle.digest('SHA-256', encoder.encode('raven-files-cursor-v2:' + secret));
  return crypto.subtle.importKey('raw', material, { name: 'AES-GCM' }, false, ['encrypt', 'decrypt']);
}
const bound = scope => encoder.encode(JSON.stringify([scope.user, scope.source, scope.path, scope.provider]));
export async function sealCursor(env, scope, providerToken, now = Date.now()) {
  if (typeof providerToken !== 'string' || !providerToken || providerToken.length > 2500) throw Error('invalid cursor');
  const payload = encoder.encode(JSON.stringify({ token: providerToken, expires: now + 15 * 60 * 1000 }));
  if (payload.length > MAX_BYTES) throw Error('invalid cursor');
  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const ciphertext = await crypto.subtle.encrypt({name:'AES-GCM',iv:nonce,additionalData:bound(scope)},await keyFor(env),payload);
  return 'v2.' + b64url(nonce) + '.' + b64url(new Uint8Array(ciphertext));
}
export async function openCursor(env, scope, cursor, now = Date.now()) {
  if (typeof cursor !== 'string' || cursor.length > 9000) throw Error('invalid cursor');
  const parts = cursor.split('.');
  if (parts.length !== 3 || parts[0] !== 'v2') throw Error('invalid cursor');
  const nonce = unb64url(parts[1]),ciphertext = unb64url(parts[2]);
  if (nonce.length !== 12 || ciphertext.length < 17 || ciphertext.length > MAX_BYTES + 16) throw Error('invalid cursor');
  let data;
  try {
    const bytes = await crypto.subtle.decrypt({name:'AES-GCM',iv:nonce,additionalData:bound(scope)},await keyFor(env),ciphertext);
    data = JSON.parse(new TextDecoder().decode(bytes));
  } catch (error) {
    if (error?.message === 'cursor service not configured') throw error;
    throw Error('invalid cursor');
  }
  if (typeof data.token !== 'string' || !data.token || data.token.length > 2500 ||
      !Number.isFinite(data.expires) || data.expires <= now || data.expires > now + 16 * 60 * 1000)
    throw Error('invalid cursor');
  return data.token;
}
