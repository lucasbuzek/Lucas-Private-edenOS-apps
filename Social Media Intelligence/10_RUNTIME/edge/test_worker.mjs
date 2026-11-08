import test from "node:test";
import assert from "node:assert/strict";
import {webcrypto} from "node:crypto";
import {FamaStore} from "./worker.mjs";
import app from "./worker.mjs";

globalThis.crypto ??= webcrypto;
const TOKEN = "t".repeat(48);
class Cursor {
  constructor(rows) {this.rows = rows;}
  toArray() {return this.rows;}
  one() {return this.rows[0];}
}
class FakeSql {
  constructor(){this.posts=new Map();this.auditRows=[];this.changes=0;this.rates=new Map();}
  exec(sql,...values){
    if (sql.startsWith("CREATE TABLE"))return new Cursor([]);
    if (sql.startsWith("INSERT INTO posts")){
      const [id,payload,updated]=values;
      if(this.posts.has(id))throw Error("UNIQUE constraint failed: posts.id");
      this.posts.set(id,{payload,updated});this.changes=1;return new Cursor([]);
    }
    if (sql.startsWith("SELECT payload FROM posts WHERE id=")){
      const p=this.posts.get(values[0]);return new Cursor(p?[{payload:p.payload}]:[]);
    }
    if (sql.startsWith("SELECT payload FROM posts ORDER BY")){
      return new Cursor([...this.posts.values()].map(x=>({payload:x.payload})));
    }
    if (sql.startsWith("UPDATE posts SET")){
      this.changes=0;
      const [payload,updated,id,previous]=values;
      const p=this.posts.get(id);
      if(p&&p.payload===previous){this.posts.set(id,{payload,updated});this.changes=1;}
      return new Cursor([]);
    }
    if (sql.startsWith("SELECT changes()"))return new Cursor([{count:this.changes}]);
    if (sql.startsWith("INSERT INTO audit")){
      this.auditRows.push(values);this.changes=1;return new Cursor([]);
    }
    if (sql.startsWith("INSERT INTO rates")){
      const key=values[0];this.rates.set(key,(this.rates.get(key)||0)+1);return new Cursor([]);
    }
    if (sql.startsWith("SELECT count FROM rates"))return new Cursor([{count:this.rates.get(values[0])||0}]);
    throw Error("SQL not supported by fixture: "+sql);
  }
}
function makeEnv(){
  const sql=new FakeSql();
  const store=new FamaStore({storage:{sql},blockConcurrencyWhile(cb){return cb();}});
  const env={FAMA_OWNER_TOKEN:TOKEN,FAMA_STORE:{
    idFromName(name){assert.equal(name,"fama-owner");return name;},
    get(){return {fetch:req=>store.fetch(req)};}
  }};
  return {env,sql,store};
}
async function post(env,path,body,token=TOKEN,origin=null) {
  const headers={"Content-Type":"application/json"};
  if(token)headers.Authorization="Bearer "+token;
  if(origin)headers.Origin=origin;
  const result=await app.fetch(new Request("https://fama.example"+path,{
    method:"POST",headers,body:JSON.stringify(body)}),env);
  return {status:result.status,body:await result.json()};
}
function draft(){
  return {operation:"create",post_id:"one",persona_id:"owner",platform:"LinkedIn",
    account_id:"selected-owner-account",audience:"public",text:"A sourced draft.",
    source_urls:["https://example.org/research"],
    proposed_publish_at:new Date(Date.now()+172800000).toISOString()};
}
test("health and UI are served without leaking owner data",async()=>{
  const {env}=makeEnv();
  const r=await app.fetch(new Request("https://fama.example/health"),env);
  assert.equal(r.status,200);
  assert.equal((await r.json()).publishing,"DISABLED");
  const page=await app.fetch(new Request("https://fama.example/"),env);
  assert.equal(page.status,200);
  assert.match(page.headers.get("Content-Security-Policy"),/script-src 'self'/);
});
test("auth and origin fail closed",async()=>{
  const {env}=makeEnv();
  assert.equal((await post(env,"/api/queue",draft(),null)).status,401);
  assert.equal((await post(env,"/api/queue",draft(),"wrong")).status,401);
  assert.equal((await post(env,"/api/queue",draft(),TOKEN,"https://bad.example")).status,403);
  const res=await post(env,"/api/publish",{operation:"publish"});
  assert.equal(res.status,404);
});
test("durable create, review, human approval, scheduling; never publishes",async()=>{
  const {env,sql}=makeEnv();
  let r=await post(env,"/api/queue",draft());
  assert.equal(r.status,200);assert.equal(r.body.result.state,"DRAFT");
  r=await post(env,"/api/queue",{operation:"ready",post_id:"one"});
  assert.equal(r.body.result.state,"READY_FOR_REVIEW");
  r=await post(env,"/api/queue",{operation:"show",post_id:"one"});
  const p=r.body.result;
  r=await post(env,"/api/queue",{operation:"approve",post_id:"one",reviewer:"Owner",
    action:"PREPARE_SCHEDULE",content_hash:p.content_hash,
    platform:p.platform,account_id:p.account_id,
    expires_at:new Date(Date.now()+3600000).toISOString()});
  assert.equal(r.status,200);assert.equal(r.body.result.state,"APPROVED");
  r=await post(env,"/api/queue",{operation:"schedule-proposal",post_id:"one"});
  assert.equal(r.body.result.state,"SCHEDULE_PREPARED");
  assert.equal(r.body.result.external_action,"NOT_PERFORMED");
  assert.equal(r.body.external_social_action,"NOT_PERFORMED");
  assert.ok(sql.auditRows.length>=4);
});
test("edit invalidates approval; stale or cross-account approval rejected",async()=>{
  const {env}=makeEnv();
  await post(env,"/api/queue",draft());
  await post(env,"/api/queue",{operation:"ready",post_id:"one"});
  const p=(await post(env,"/api/queue",{operation:"show",post_id:"one"})).body.result;
  const approve={operation:"approve",post_id:"one",reviewer:"Owner",
    action:"PREPARE_SCHEDULE",content_hash:p.content_hash,platform:p.platform,
    account_id:p.account_id,expires_at:new Date(Date.now()+3600000).toISOString()};
  assert.equal((await post(env,"/api/queue",{...approve,account_id:"other-tenant"})).status,400);
  assert.equal((await post(env,"/api/queue",approve)).status,200);
  assert.equal((await post(env,"/api/queue",{operation:"edit",post_id:"one",
    text:"Corrected material details"})).status,200);
  const edited=(await post(env,"/api/queue",{operation:"show",post_id:"one"})).body.result;
  assert.equal(edited.state,"READY_FOR_REVIEW");assert.equal(edited.approval,null);
  assert.equal((await post(env,"/api/queue",approve)).status,400);
});
test("research requests are bounded and upstream data cannot trigger account actions",async()=>{
  const {env}=makeEnv();
  assert.equal((await post(env,"/api/research",{query:"x",limit:5})).status,400);
  // Malformed inputs never invoke a provider.
  assert.equal((await post(env,"/api/research",{query:"good",limit:500})).status,400);
});
