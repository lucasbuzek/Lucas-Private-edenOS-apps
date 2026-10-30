import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {webcrypto} from 'node:crypto';
globalThis.crypto ??= webcrypto;
// Import exact production JS as ESM without relying on package.json module type.
const source = readFileSync(new URL('../functions/api/file-cursor.js', import.meta.url));
const {sealCursor, openCursor} = await import('data:text/javascript;base64,' + source.toString('base64'));
const env = {RAVEN_FILES_CURSOR_KEY:'isolated-test-only-signing-secret-with-at-least-thirty-two-characters'};
const scope={user:'owner',source:'research',path:'/folder',provider:'dropbox'};
test('approved cursor roundtrip',async()=>{
 const c=await sealCursor(env,scope,'provider-token',1000);
 assert.equal(await openCursor(env,scope,c,1100),'provider-token');
});
test('rejects cross-user, cross-source, cross-folder and cross-provider replay',async()=>{
 const c=await sealCursor(env,scope,'provider-token',1000);
 for(const k of ['user','source','path','provider'])await assert.rejects(openCursor(env,{...scope,[k]:'other'},c,1100),/invalid cursor/);
});
test('rejects tampering and expiry',async()=>{
 const c=await sealCursor(env,scope,'provider-token',1000);
 await assert.rejects(openCursor(env,scope,c.slice(0,-2)+'aa',1100),/invalid cursor/);
 await assert.rejects(openCursor(env,scope,c,1000+15*60*1000),/invalid cursor/);
});
test('denies token use when signing secret is not provisioned',async()=>{
 const c=await sealCursor(env,scope,'provider-token',1000);
 await assert.rejects(sealCursor({},scope,'provider-token',1000),/not configured/);
 await assert.rejects(openCursor({},scope,c,1100),/not configured/);
});
test('rejects overly long cursors and empty provider tokens',async()=>{
 await assert.rejects(openCursor(env,scope,'a'.repeat(10000),1100),/invalid cursor/);
 await assert.rejects(sealCursor(env,scope,'',1000),/invalid cursor/);
});
