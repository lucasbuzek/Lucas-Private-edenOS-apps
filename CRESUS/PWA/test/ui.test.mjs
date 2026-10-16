import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const html = readFileSync(new URL('../public/index.html', import.meta.url), 'utf8');
const js = readFileSync(new URL('../public/app.js', import.meta.url), 'utf8');
const css = readFileSync(new URL('../public/styles.css', import.meta.url), 'utf8');
const sw = readFileSync(new URL('../public/sw.js', import.meta.url), 'utf8');

const workspaces = ['Overview', 'Research', 'Watchlist', 'Portfolio', 'ZACCHAEUS', 'Strategy Lab', 'Evidence', 'Providers'];

test('persistent workspace rail exposes all eight CRESUS areas', () => {
  assert.match(html, /<nav id="workspaceNav"[^>]*aria-label="CRESUS workspaces"/);
  for (const label of workspaces) assert.ok(html.includes(`>${label}</button>`), `missing ${label}`);
});

test('workspace buttons have real click handlers and authenticated chat actions', () => {
  assert.match(js, /function selectWorkspace\(key\)/);
  assert.match(js, /document\.querySelectorAll\('\.workspace-btn'\)/);
  assert.match(js, /b\.addEventListener\('click', \(\) => selectWorkspace\(b\.dataset\.workspace\)\)/);
  assert.match(js, /\$\('input'\)\.value = item\.prompt/);
  assert.match(js, /\$\('composer'\)\.requestSubmit\(\)/);
  assert.match(js, /claim brokerage connectivity/i);
  assert.match(js, /claim a backtest ran unless it actually did/i);
});

test('workspace rail is responsive and exposes active state accessibly', () => {
  assert.match(css, /\.workspace-nav\s*\{[^}]*flex:\s*none/s);
  assert.match(css, /\.workspace-btn\[aria-pressed="true"\]/);
  assert.match(css, /\.workspace-label\s*\{ display: none; \}/);
  assert.match(html, /aria-pressed="true"/);
});

test('service worker cache advances with the updated app shell', () => {
  assert.match(sw, /const CACHE = 'cresus-shell-v3'/);
  assert.match(sw, /'\/index\.html'.*'\/styles\.css'.*'\/app\.js'/s);
});
