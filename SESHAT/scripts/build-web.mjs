import { cp, mkdir, rm, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { join, dirname } from "node:path";
const root = fileURLToPath(new URL("../", import.meta.url));
const dest = join(root, "dist");
await rm(dest, { recursive: true, force: true });
await mkdir(dest, { recursive: true });
const allow = [
  ["web/index.html","index.html"],["web/app.mjs","app.mjs"],["web/styles.css","styles.css"],
  ["web/manifest.webmanifest","manifest.webmanifest"],["web/sw.js","sw.js"],["web/icon.svg","icon.svg"],
  ["src/domain/ledger.mjs","src/domain/ledger.mjs"],["src/domain/queries.mjs","src/domain/queries.mjs"],
  ["src/domain/catalogue.mjs","src/domain/catalogue.mjs"],
  ["src/domain/csv-import.mjs","src/domain/csv-import.mjs"],
  ["src/persistence/snapshot.mjs","src/persistence/snapshot.mjs"],
  ["src/persistence/browser-idb.mjs","src/persistence/browser-idb.mjs"],
  ["fixtures/demo-inventory.mjs","fixtures/demo-inventory.mjs"],
];
for (const [source,target] of allow) {
  const from = join(root, source), to = join(dest, target);
  await mkdir(dirname(to), { recursive: true });
  await cp(from, to);
}
const html = await readFile(join(dest,"index.html"),"utf8");
if (!html.includes('src="./app.mjs"') || !html.includes('href="./manifest.webmanifest"')) throw new Error("Missing PWA entrypoints.");
console.log("SESHAT static PWA assets built:",allow.length,"allowlisted files. No private docs, tests, or credentials copied.");
