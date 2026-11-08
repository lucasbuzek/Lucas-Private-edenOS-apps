import test from "node:test";
import assert from "node:assert/strict";
import {appPath} from "../src/runtime.js";
import {readFileSync} from "node:fs";
test("standalone and RAVENaIntelligence use same-origin scoped API paths",()=>{
 assert.equal(appPath("api/official/sa-ocds","/"),"/api/official/sa-ocds");
 assert.equal(appPath("api/official/sa-ocds","/ravenapps/tenders/"),"/ravenapps/tenders/api/official/sa-ocds");
 assert.equal(appPath("sw.js","/ravenapps/tenders/"),"/ravenapps/tenders/sw.js");
});
test("base-path helper rejects cross-origin, traversal and ambiguous paths",()=>{
 for(const x of ["/api/private","../admin","https://evil.test/x","?token=x","foo#x","x\\y"])assert.throws(()=>appPath(x,"/ravenapps/tenders/"),/Unsafe/);
 for(const base of ["//evil.test/","/x//y/","https://example.test/","/x",""])assert.throws(()=>appPath("sw.js",base),/Invalid/);
});
test("service worker remains scoped to TENDERS and never purges unrelated RAVEN caches",()=>{
 const source=readFileSync(new URL("../public/sw.js",import.meta.url),"utf8");
 assert.match(source,/registration\.scope/);
 assert.match(source,/startsWith\(CACHE_PREFIX\)/);
 assert.match(source,/assets\//);
 assert.match(source,/!staticAsset/);
});
