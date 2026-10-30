import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdtemp,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {DatabaseSync} from 'node:sqlite';
const source=await readFile(new URL('../functions/api/knowledge.js',import.meta.url),'utf8');
const template=source.replace("import {verifyAccessJwt} from './[[path]].js';",`async function verifyAccessJwt(token){if(token!=='valid-owner'&&token!=='valid-guest')throw Error('unauthorized');return {sub:token==='valid-owner'?'sub-owner':'sub-guest',email:token==='valid-owner'?'owner@example.test':'guest@example.test',exp:Math.floor(Date.now()/1000)+3600}}`);
const dir=await mkdtemp(path.join(tmpdir(),'raven-library-'));await writeFile(path.join(dir,'route.mjs'),template);
const {onRequest}=await import(pathToFileURL(path.join(dir,'route.mjs')).href);
const db=new DatabaseSync(':memory:');db.exec("PRAGMA foreign_keys=ON; CREATE TABLE users(id TEXT PRIMARY KEY,subject TEXT,email TEXT,disabled_at INTEGER)");
db.exec(await readFile(new URL('../migrations/0004_library_sources.sql',import.meta.url),'utf8'));
db.prepare('INSERT INTO users(id,subject,email) VALUES(?,?,?)').run('user-owner','sub-owner','owner@example.test');
db.prepare('INSERT INTO users(id,subject,email) VALUES(?,?,?)').run('user-guest','sub-guest','guest@example.test');
function adapter(database){return {prepare(sql){const statement=database.prepare(sql);return {bind(...params){return {first:async()=>statement.get(Object.fromEntries(params.map((v,i)=>[String(i+1),v]))),all:async()=>({results:statement.all(Object.fromEntries(params.map((v,i)=>[String(i+1),v])))}),run:async()=>({meta:statement.run(Object.fromEntries(params.map((v,i)=>[String(i+1),v])))})}}}}}}
const env={DB:adapter(db)};
function req(method='GET',p='',token='valid-owner',body){return new Request('https://raven.example.test/api/knowledge'+p,{method,headers:{'cf-access-jwt-assertion':token,'content-type':'application/json',...(method==='POST'?{'origin':'https://raven.example.test'}:{})},body:body?JSON.stringify(body):undefined})}
async function call(request){const r=await onRequest({request,env});return {status:r.status,json:await r.json()}}
let created;
test('unauthenticated requests reveal no metadata',async()=>{const r=await call(req('GET','','invalid'));assert.equal(r.status,401)});
test('private HTTPS source is immediately listed only to its owner',async()=>{const r=await call(req('POST','','valid-owner',{title:'Internet-in-a-Box',url:'https://internet-in-a-box.org/',description:'Offline knowledge catalog',kind:'documentation'}));assert.equal(r.status,201);created=r.json.id;const own=await call(req());assert.equal(own.json.items.length,1);assert.equal(own.json.items[0].title,'Internet-in-a-Box');assert.equal(own.json.items[0].review_status,'link-only');const guest=await call(req('GET','','valid-guest'));assert.deepEqual(guest.json.items,[])});
test('non-owner cannot enumerate private item IDs',async()=>{const x=await call(req('GET','?action=get&id='+created,'valid-guest'));assert.equal(x.status,404)});
test('cross-tenant explicit grant requires granted visibility',async()=>{db.prepare('INSERT INTO raven_library_grants(source_id,user_id,can_read) VALUES (?,?,?)').run(created,'user-guest',1);assert.equal((await call(req('GET','','valid-guest'))).json.items.length,0);db.prepare("UPDATE raven_library_sources SET visibility='granted' WHERE id=?").run(created);assert.equal((await call(req('GET','','valid-guest'))).json.items.length,1);db.prepare('UPDATE raven_library_grants SET revoked_at=? WHERE source_id=?').run(Date.now(),created);assert.equal((await call(req('GET','','valid-guest'))).json.items.length,0)});
test('search uses bound parameters and returns matching descriptions',async()=>{const r=await call(req('GET','?q=Offline'));assert.equal(r.status,200);assert.equal(r.json.items.length,1);const none=await call(req('GET','?q=SECRET-KEY'));assert.equal(none.json.items.length,0)});
test('foreign origin and non-HTTPS links rejected',async()=>{const body={title:'Bad',url:'http://localhost/internal'};assert.equal((await call(req('POST','','valid-owner',body))).status,400);const mismatch=req('POST','','valid-owner',{title:'Good',url:'https://docs.example.org/'});mismatch.headers.set('origin','https://evil.example.org');assert.equal((await call(mismatch)).status,403)});
test('unknown input fields and internal host labels rejected',async()=>{assert.equal((await call(req('POST','','valid-owner',{title:'Wrong',url:'https://example.org/',visibility:'public'}))).status,400);assert.equal((await call(req('POST','','valid-owner',{title:'Wrong',url:'https://192.168.0.1/'}))).status,400)});
test('GET other actions and invalid ids denied',async()=>{assert.equal((await call(req('GET','?action=remove'))).status,404);assert.equal((await call(req('GET','?action=get&id=bogus'))).status,404)});
process.on('exit',()=>{db.close()});
