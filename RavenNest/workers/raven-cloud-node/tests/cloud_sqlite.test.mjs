import test from "node:test";
import assert from "node:assert/strict";
import {DatabaseSync} from "node:sqlite";
import {tick} from "../src/index.js";

function database() {
  const sqlite = new DatabaseSync(":memory:");
  sqlite.exec("CREATE TABLE node_state (node_id TEXT PRIMARY KEY, meta TEXT NOT NULL, state TEXT NOT NULL, updated_at INTEGER NOT NULL)");
  sqlite.exec("CREATE TABLE actions (id TEXT PRIMARY KEY, node_id TEXT NOT NULL, capability TEXT NOT NULL, params TEXT NOT NULL, status TEXT NOT NULL, origin TEXT, created_at INTEGER NOT NULL, claimed_at INTEGER, completed_at INTEGER, result TEXT)");
  return {
    sqlite,
    d1:{prepare(sql){return{bind(...args){
      const statement=sqlite.prepare(sql);
      return {
        async run(){const result=statement.run(...args);return{meta:{changes:result.changes}};},
        async first(){return statement.get(...args)??null;},
      };
    }};}},
  };
}

test("cloud cron really executes a D1-style SQLite queue and retains precise state",async()=>{
  const {sqlite,d1}=database();
  try {
    const now=Date.now();
    const q=sqlite.prepare("INSERT INTO actions(id,node_id,capability,params,status,created_at,claimed_at,completed_at,result) VALUES(?,?,?,?,?,?,?,?,?)");
    q.run("act_"+"1".repeat(20),"lucas-cloud","ai.infer",
      JSON.stringify({prompt:"Summarize a safe sentence",consent:"send_to_cloud_provider"}),
      "queued",now,null,null,null);
    q.run("act_"+"2".repeat(20),"lucas-cloud","cloud.state.refresh","{}",
      "claimed",now-800000,now-800000,null,null);
    q.run("act_"+"3".repeat(20),"lucas-cloud","ai.infer","{\"redacted\":true}",
      "succeeded",now-10*86400000,null,now-9*86400000,'{"output":"old sensitive result"}');
    q.run("act_"+"4".repeat(20),"lucas-cloud","ai.infer",
      JSON.stringify({prompt:"Expired unpublished text",consent:"send_to_cloud_provider"}),
      "queued",now-300000,null,null,null);
    const env={DB:d1,RAVEN_AI_PROVIDER:"workers-ai",RAVEN_AI_MODEL:"@cf/unit-test",
      AI:{run:async()=>({response:"AI ran in cloud"})}};
    await tick(env);
    let state=sqlite.prepare("SELECT status,params,result FROM actions WHERE id=?");
    const completed=state.get("act_"+"1".repeat(20));
    assert.equal(completed.status,"succeeded");
    assert.equal(JSON.parse(completed.params).redacted,true);
    assert.equal(JSON.parse(completed.result).output,"AI ran in cloud");
    assert.equal(state.get("act_"+"2".repeat(20)).status,"failed");
    assert.equal(state.get("act_"+"3".repeat(20)).result,null);
    const expired=state.get("act_"+"4".repeat(20));
    assert.equal(expired.status,"expired");
    assert.equal(JSON.parse(expired.params).redacted,true);
    const node=sqlite.prepare("SELECT * FROM node_state WHERE node_id='lucas-cloud'").get();
    assert.ok(node);
    assert.ok(JSON.parse(node.meta).actions.includes("ai.infer"));
  } finally {sqlite.close();}
});
