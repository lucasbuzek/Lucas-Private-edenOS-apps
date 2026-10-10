import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
const source=fs.readFileSync(new URL("../functions/api/[[path]].js",import.meta.url),"utf8");
const api=await import("data:text/javascript;base64,"+Buffer.from(source).toString("base64"));
const owner={role:"owner",legacy:false,grants:[]};
const member={role:"member",legacy:false,grants:[{device_id:"lucas-macbook",capability:"power.keepawake.start"}]};
const value=(over={})=>({intent:"action",topic:"keepawake",capability:"power.keepawake.start",params:{minutes:30},node_id:"lucas-macbook",...over});
test("strict classifier accepts a granted, validated action",()=>assert.deepEqual(api.validateChatClassification(value(),member),value()));
test("classifier rejects unknown keys, wrong types and malformed parameters",()=>{assert.equal(api.validateChatClassification({...value(),extra:true},owner),null);assert.equal(api.validateChatClassification(value({params:{minutes:999}}),owner),null);assert.equal(api.validateChatClassification(value({node_id:42}),owner),null)});
test("classifier rejects an ungranted capability and every sensitive capability",()=>{assert.equal(api.validateChatClassification(value({capability:"power.keepawake.stop",params:{}}),member),null);assert.equal(api.validateChatClassification(value({capability:"codex.cloud.submit",topic:"codex",params:{}}),owner),null)});
test("non-action classifications cannot smuggle a capability",()=>assert.equal(api.validateChatClassification(value({intent:"status"}),owner),null));
test("chat implementation has timeout, limits, audit, fallback and no raw model response",()=>{assert.match(source,/setTimeout\(\(\)=>controller\.abort\(\),8000\)/);assert.match(source,/CHAT_DAILY_LIMIT/);assert.match(source,/CHAT_USER_PER_MIN/);assert.match(source,/INSERT INTO chat_audit/);assert.match(source,/Raven assistant is unavailable or unsure/);assert.doesNotMatch(source,/reply=.*c\.raw/)});
test("evaluation corpus has at least 30 cases and unsafe refusals",()=>{const q=JSON.parse(fs.readFileSync(new URL("chat_eval/questions.json",import.meta.url)));assert.ok(q.length>=30);assert.ok(q.filter(x=>x.expected.refusal).length>=8)});

test("provider adapter handles canned, empty, malformed and rejected fetch outputs",async()=>{const old=globalThis.fetch;try{globalThis.fetch=async()=>({ok:true,json:async()=>({choices:[{message:{content:JSON.stringify(value())}}]})});let r=await api.classifyChat({GROQ_API_KEY:"fake-test-value"},"wake",[]);assert.ok(api.validateChatClassification(JSON.parse(r.raw),owner));globalThis.fetch=async()=>({ok:true,json:async()=>({choices:[{message:{content:""}}]})});r=await api.classifyChat({GROQ_API_KEY:"fake-test-value"},"wake",[]);assert.equal(r.raw,"");globalThis.fetch=async()=>({ok:true,json:async()=>({choices:[{message:{content:"not json"}}]})});r=await api.classifyChat({GROQ_API_KEY:"fake-test-value"},"wake",[]);assert.throws(()=>JSON.parse(r.raw));globalThis.fetch=async()=>{throw Error("timeout")};r=await api.classifyChat({GROQ_API_KEY:"fake-test-value"},"wake",[]);assert.equal(r.raw,undefined)}finally{globalThis.fetch=old}});
