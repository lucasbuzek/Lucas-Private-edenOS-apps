/**
 * Per-app preview deployment commands only.
 * Never create sites, link a different site, publish production, or deploy a Worker
 * using the application's authoritative Wrangler configuration.
 */
export function previewCommand(manifest, outputDirectory) {
  const deployment = manifest?.deployment;
  const target = deployment?.targetId;
  if (typeof target !== 'string' || !/^[A-Za-z0-9][A-Za-z0-9_-]{1,127}$/.test(target)) {
    throw new Error('An explicit existing app-specific hosting target is required');
  }
  if (deployment.provider === 'netlify' && deployment.kind === 'static-pwa') {
    // Netlify deploy is a draft by default; --no-build uses the isolated preflight output.
    return ['netlify', 'deploy', '--site', target, '--dir', outputDirectory, '--no-build', '--json'];
  }
  if (deployment.provider === 'cloudflare-pages' && deployment.kind === 'static-pwa') {
    const branch = 'edenos-pwa-preview-' + manifest.app.id;
    if (deployment.productionBranch === branch) {
      throw new Error('Preview branch equals the production branch');
    }
    return ['wrangler', 'pages', 'deploy', outputDirectory, '--project-name', target, '--branch', branch];
  }
  if (deployment.provider === 'cloudflare-workers' && deployment.kind === 'worker-pwa') {
    throw new Error('Cloudflare Worker preview requires an isolated preview Worker, separate D1 and verified Access policy; not enabled');
  }
  throw new Error('Unsupported preview hosting adapter');
}

export function extractPreviewUrl(output, host) {
  for (const line of String(output || '').split(/\r?\n/).reverse()) {
    try {
      const parsed = JSON.parse(line);
      const value = parsed.deploy_url || parsed.deployUrl || parsed.url;
      if (typeof value === 'string' && validHost(value, host)) return value;
    } catch { /* non-JSON CLI output */ }
  }
  // Scan full URL tokens. Never accept a regex prefix of a hostile hostname such
  // as https://site.netlify.app.attacker.example.
  for (const token of String(output || '').match(/https:\/\/[^\s"'<>()[\]]+/g) || []) {
    const candidate = token.replace(/[,;)]+$/, '');
    if (validHost(candidate, host)) return candidate;
  }
  return null;
}

function validHost(value, provider) {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && !url.username && !url.password && url.pathname === '/' &&
      (provider === 'netlify' ? url.hostname.endsWith('.netlify.app') :
        provider === 'cloudflare-pages' ? url.hostname.endsWith('.pages.dev') : false);
  } catch { return false; }
}
