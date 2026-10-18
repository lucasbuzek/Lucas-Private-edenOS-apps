/**
 * Verify existing provider-owned target identity read-only before any build/upload.
 * Credentials and response bodies are never logged.
 */
function canonicalHost(value) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash ||
        url.pathname !== '/') return null;
    return url.hostname.toLowerCase();
  } catch { return null; }
}

function verifiedOrigin(manifest) {
  const host = canonicalHost(manifest?.deployment?.siteUrl);
  if (!host) throw new Error('Configured HTTPS siteUrl is required to verify the existing hosting target');
  return host;
}

async function getJson(url, token, fetchImpl) {
  const response = await fetchImpl(url, {
    method: 'GET',
    headers: { authorization: 'Bearer ' + token, accept: 'application/json' },
    redirect: 'error',
    signal: AbortSignal.timeout(12000),
  });
  if (!response.ok) throw new Error('Hosting provider rejected the read-only project identity check (HTTP ' + response.status + ')');
  return response.json();
}

export async function verifyHostingTarget(manifest, { env = process.env, fetchImpl = fetch } = {}) {
  const d = manifest?.deployment;
  const target = d?.targetId;
  if (!target || !/^[A-Za-z0-9][A-Za-z0-9_-]{1,127}$/.test(target)) {
    throw new Error('A verified existing app-specific hosting target is required');
  }
  const originHost = verifiedOrigin(manifest);
  if (typeof fetchImpl !== 'function') throw new Error('Hosting identity verification requires fetch');

  if (d.provider === 'netlify' && d.kind === 'static-pwa') {
    const token = env.NETLIFY_AUTH_TOKEN;
    if (!token) throw new Error('Netlify hosting credentials are unavailable');
    if (!d.expectedName || !/^[a-zA-Z0-9][a-zA-Z0-9_-]+$/.test(d.expectedName)) {
      throw new Error('Netlify target needs a verified expectedName distinct from the site ID');
    }
    const site = await getJson('https://api.netlify.com/api/v1/sites/' + encodeURIComponent(target), token, fetchImpl);
    const domains = [site?.ssl_url, site?.custom_domain, ...(Array.isArray(site?.domain_aliases) ? site.domain_aliases : [])]
      .map(s => typeof s === 'string' && !s.startsWith('http') ? 'https://' + s : s)
      .map(canonicalHost).filter(Boolean);
    if (site?.id !== target || site?.name !== d.expectedName || !domains.includes(originHost)) {
      throw new Error('Netlify site ID/name/origin did not match the declared app deployment');
    }
    return { provider: 'netlify', targetId: target, verifiedOrigin: originHost };
  }

  if (d.provider === 'cloudflare-pages' && d.kind === 'static-pwa') {
    const token = env.CLOUDFLARE_API_TOKEN;
    const account = env.CLOUDFLARE_ACCOUNT_ID;
    if (!token || !/^[a-f0-9]{32}$/i.test(account || '')) {
      throw new Error('Cloudflare Pages API token and account ID are required');
    }
    if (!/^[a-z0-9][a-z0-9-]*$/.test(target)) {
      throw new Error('Cloudflare Pages target must be the exact existing project name');
    }
    const data = await getJson(
      'https://api.cloudflare.com/client/v4/accounts/' + account +
      '/pages/projects/' + encodeURIComponent(target), token, fetchImpl);
    const project = data?.result;
    const knownDomains = [project?.subdomain, ...(Array.isArray(project?.domains) ? project.domains : [])]
      .map(s => typeof s === 'string' && !s.startsWith('http') ? 'https://' + s : s)
      .map(canonicalHost).filter(Boolean);
    const previewBranch = 'edenos-pwa-preview-' + manifest.app.id;
    if (data?.success !== true || project?.name !== target ||
        project.production_branch === previewBranch || !knownDomains.includes(originHost)) {
      throw new Error('Cloudflare Pages project/name/origin or safe preview branch check failed');
    }
    return { provider: 'cloudflare-pages', targetId: target, verifiedOrigin: originHost };
  }
  throw new Error('Worker PWA publication is not enabled without independently protected preview infrastructure');
}
