import test from "node:test";
import assert from "node:assert/strict";
import {aiConfiguration,validateAIParams,performAI} from "../src/ai_provider.js";
import {validate,tick} from "../src/index.js";

const consent="send_to_cloud_provider";
const task={prompt:"Summarize: the bridge is online.",consent};
function fakeDB(action) {
  const calls=[];
  return {calls,prepare(sql) {
    return {bind(...args) {
      calls.push({sql,args});
      return {
        async run(){return{meta:{changes:1}};},
        async first(){return sql.startsWith("UPDATE actions SET status='claimed'")?action:null;}
      };
    }};
  }};
}

test("cloud AI disabled without explicit provider, model, and credential",()=>{
  assert.equal(aiConfiguration({}).configured,false);
  assert.equal(aiConfiguration({RAVEN_AI_PROVIDER:"groq",RAVEN_AI_MODEL:"test"}).configured,false);
  assert.equal(aiConfiguration({RAVEN_AI_PROVIDER:"groq",RAVEN_AI_MODEL:"test",GROQ_API_KEY:"private"}).configured,true);
  assert.equal(aiConfiguration({RAVEN_AI_PROVIDER:"workers-ai",RAVEN_AI_MODEL:"@cf/test",AI:{}}).configured,true);
  assert.equal(aiConfiguration({RAVEN_AI_PROVIDER:"unknown",RAVEN_AI_MODEL:"test",GROQ_API_KEY:"private"}).configured,false);
});

test("AI tasks require explicit consent and strictly bounded prompt",()=>{
  assert.equal(validateAIParams(task),true);
  assert.equal(validate("ai.infer",task),true);
  for(const params of [{prompt:"text"}, {prompt:"text",consent:"no"},
    {prompt:"",consent}, {prompt:" ".repeat(3),consent},
    {prompt:"x".repeat(2001),consent},
    {prompt:"hello",consent,extra:"unexpected"},null,[]]) {
    assert.equal(validate("ai.infer",params),false);
  }
  assert.equal(validate("shell.run",{}),false);
});

test("Groq success returns response, not provider secrets or Mac data",async()=>{
  const previous=globalThis.fetch;
  let recorded=null;
  globalThis.fetch=async(url,options)=>{
    recorded={url,options};
    return {ok:true,json:async()=>({choices:[{message:{content:"Provider result"}}]})};
  };
  try {
    const output=await performAI({
      RAVEN_AI_PROVIDER:"groq",RAVEN_AI_MODEL:"chosen-model",GROQ_API_KEY:"test-key",
    },task);
    assert.equal(output.ok,true);
    assert.equal(output.result.output,"Provider result");
    assert.equal(output.result.deviceExecution,false);
    assert.equal(output.result.provider,"groq");
    assert.match(recorded.url,/api.groq.com/);
    assert.equal(recorded.options.method,"POST");
    assert.equal(JSON.parse(recorded.options.body).messages.at(-1).content,task.prompt);
    assert.ok(!JSON.stringify(output).includes("test-key"));
  } finally {globalThis.fetch=previous;}
});

test("Cloudflare Workers AI binding handles text without a Mac",async()=>{
  let asked=null;
  const output=await performAI({
    RAVEN_AI_PROVIDER:"workers-ai",RAVEN_AI_MODEL:"@cf/test",
    AI:{run:async(model,body)=>{asked={model,body};return{response:"Cloudflare result"};}},
  },task);
  assert.equal(output.ok,true);
  assert.equal(asked.model,"@cf/test");
  assert.equal(output.result.output,"Cloudflare result");
});

test("missing provider and empty upstream output are failures",async()=>{
  assert.equal((await performAI({},task)).result.status,"NOT_CONFIGURED");
  const old=globalThis.fetch;
  globalThis.fetch=async()=>({ok:true,json:async()=>({choices:[{message:{content:""}}]})});
  try {
    const output=await performAI({
      RAVEN_AI_PROVIDER:"groq",RAVEN_AI_MODEL:"test",GROQ_API_KEY:"fake",
    },task);
    assert.equal(output.ok,false);
    assert.equal(output.result.status,"NO_OUTPUT");
  } finally {globalThis.fetch=old;}
});

test("cloud queue completes inference and redacts prompt",async()=>{
  const DB=fakeDB({id:"act_"+"a".repeat(20),capability:"ai.infer",params:JSON.stringify(task)});
  await tick({DB,RAVEN_AI_PROVIDER:"workers-ai",RAVEN_AI_MODEL:"@cf/test",
    AI:{run:async()=>({response:"Completed in cloud"})}});
  const update=DB.calls.find(c=>c.sql.startsWith("UPDATE actions SET status=?1"));
  assert.equal(update.args[0],"succeeded");
  assert.match(update.sql,/redacted/);
  assert.match(update.args[2],/Completed in cloud/);
  const published=DB.calls.find(c=>c.sql.includes("INSERT INTO node_state"));
  const meta=JSON.parse(published.args[1]);
  assert.ok(meta.actions.includes("ai.infer"));
  assert.ok(!meta.actions.includes("shell.run"));
});

test("unconfigured cloud node does not advertise ai.infer",async()=>{
  const DB=fakeDB(null);
  await tick({DB});
  const published=DB.calls.find(c=>c.sql.includes("INSERT INTO node_state"));
  const meta=JSON.parse(published.args[1]);
  assert.ok(!meta.actions.includes("ai.infer"));
  assert.ok(meta.actions.includes("github.repos.status"));
});

test("cloud cron expires abandoned claims and redacts aged model results independently",async()=>{
  const DB=fakeDB(null);
  await tick({DB});
  const timeout=DB.calls.find(c=>c.sql.includes("CLAIM_TIMEOUT"));
  assert.ok(timeout);
  assert.match(timeout.sql,/status='claimed'/);
  assert.match(timeout.sql,/redacted/);
  assert.equal(timeout.args[1],"lucas-cloud");
  const retention=DB.calls.find(c=>c.sql.includes("SET result=NULL"));
  assert.ok(retention);
  assert.match(retention.sql,/capability='ai.infer'/);
  assert.match(retention.sql,/completed_at/);
  assert.equal(retention.args[0],"lucas-cloud");
  assert.ok(retention.args[1] < Date.now());
});
