import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
const source=fs.readFileSync(new URL("../functions/api/[[path]].js",import.meta.url),"utf8");
const api=await import("data:text/javascript;base64,"+Buffer.from(source).toString("base64"));
const ok=(content)=>({ok:true,status:200,json:async()=>({choices:[{message:{content}}]})});
const err=(status)=>({ok:false,status,json:async()=>({})});
function withFetch(responses,fn){const calls=[];const orig=globalThis.fetch;globalThis.fetch=async(url,init)=>{calls.push(JSON.parse(init.body).model);return responses.shift()};return fn().finally(()=>{globalThis.fetch=orig}).then(r=>({r,calls}))}
const env={CHAT_PROVIDER:"groq",GROQ_API_KEY:"fake-key-for-tests"};
test("default Groq model is the free gpt-oss-120b",async()=>{const {calls}=await withFetch([ok("{}")],()=>api.classifyChat(env,"is my mac online",["power.keepawake.start"]));assert.deepEqual(calls,["openai/gpt-oss-120b"])});
test("429 on the main model falls back to gpt-oss-20b",async()=>{const {r,calls}=await withFetch([err(429),ok('{"intent":"help"}')],()=>api.classifyChat(env,"help",[]));assert.deepEqual(calls,["openai/gpt-oss-120b","openai/gpt-oss-20b"]);assert.equal(r.raw,'{"intent":"help"}')});
test("a 400 error does not try other models",async()=>{const {r,calls}=await withFetch([err(400)],()=>api.classifyChat(env,"help",[]));assert.deepEqual(calls,["openai/gpt-oss-120b"]);assert.equal(r.raw,undefined)});
test("CHAT_MODEL and CHAT_MODEL_FALLBACKS override the defaults",async()=>{const {calls}=await withFetch([err(503),err(429),ok("{}")],()=>api.classifyChat({...env,CHAT_MODEL:"a",CHAT_MODEL_FALLBACKS:"b, c"},"x",[]));assert.deepEqual(calls,["a","b","c"])});
