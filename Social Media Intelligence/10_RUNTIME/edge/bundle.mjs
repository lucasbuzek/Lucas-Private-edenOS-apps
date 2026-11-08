#!/usr/bin/env node
// Rebuild Cloudflare Worker deterministically from the original FAMA UI and
// isolated owner cloud adapter. Never bundle tokens, accounts or user data.
import {readFile, writeFile, mkdir} from "node:fs/promises";
import {fileURLToPath} from "node:url";
import {dirname, join, resolve} from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "..");
let code = await readFile(join(here, "worker.mjs"), "utf8");
for (const [marker, filename] of [
  ["__FAMA_HTML__", "index.html"], ["__FAMA_JS__", "app.js"], ["__FAMA_CSS__", "style.css"]
]) {
  const asset = await readFile(join(root, "web", filename), "utf8");
  const target = JSON.stringify(marker);
  if (code.split(target).length !== 2) throw Error("Expected one marker: " + marker);
  code = code.replace(target, JSON.stringify(asset));
}
const dest = join(here, "dist");
await mkdir(dest, {recursive:true});
await writeFile(join(dest, "fama-worker.mjs"), code, "utf8");
console.log("FAMA edge bundle generated from original UI and adapter; no deployment performed.");
