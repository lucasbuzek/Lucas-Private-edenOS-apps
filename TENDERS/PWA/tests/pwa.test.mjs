import test from "node:test";
import assert from "node:assert/strict";
import { readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
const root = fileURLToPath(new URL("../", import.meta.url));
test("PWA manifest declares installable identity and raster icons", async () => {
  const manifest = JSON.parse(await readFile(join(root, "public/manifest.webmanifest"), "utf8"));
  assert.equal(manifest.short_name, "TENDERS");
  assert.equal(manifest.display, "standalone");
  assert.ok(manifest.start_url);
  assert.ok(manifest.icons.some(icon => icon.sizes === "192x192"));
  for (const icon of ["tenders-180.png", "tenders-192.png", "tenders-512.png"]) {
    assert.ok((await stat(join(root, "public/icons", icon))).size > 100);
  }
});
test("service worker caches app shell and provides offline navigation fallback", async () => {
  const sw = await readFile(join(root, "public/sw.js"), "utf8");
  assert.match(sw, /addEventListener\(['"]install/);
  assert.match(sw, /addEventListener\(['"]fetch/);
  assert.match(sw, /cache\.match\(["']\/index\.html["']\)/);
  assert.match(sw, /await cache\.put\(request, response\.clone\(\)\)/);
  assert.match(sw, /tenders-shell-v3/);
});
test("connectors are explicitly unconfigured by default", async () => {
  const app = await readFile(join(root, "src/main.jsx"), "utf8");
  assert.match(app, /PLANNED · NOT CONNECTED/);
  assert.match(app, /NOT CONNECTED/);
  assert.match(app, /readWorkspace\(\)\.records/);
  const storage = await readFile(join(root, "src/storage.js"), "utf8");
  assert.match(storage, /tenders-records-v1/);
  assert.match(storage, /tenders-workspace-v2/);
});
