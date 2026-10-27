"use strict";
const assert=require("node:assert/strict"),test=require("node:test"),vm=require("node:vm"),fs=require("node:fs"),path=require("node:path");
const source=fs.readFileSync(path.join(__dirname,"webmcp-status.js"),"utf8");
function setup(reply,supported=true,withUi=false){
 const tools=[],requests=[],listeners={};
 const button={disabled:false,addEventListener(k,cb){listeners[k]=cb}},output={textContent:""};
 const document={getElementById(k){return withUi?(k==="statusCheck"?button:k==="statusOutput"?output:null):null}};
 if(supported)document.modelContext={registerTool(t){tools.push(t)}};
 const sandbox={document,fetch:async (url,opts)=>{requests.push({url,opts});if(reply instanceof Error)throw reply;return reply},localStorage:{getItem(){throw Error("must not read secrets")}}};
 vm.runInNewContext(source,sandbox,{timeout:1000});return {tools,requests,button,output,listeners};
}
const result=(status,data,type="application/json")=>({status,ok:status>=200&&status<300,headers:{get:()=>type},json:async()=>data});
test("unsupported WebMCP API does not register tools",()=>{const x=setup(null,false);assert.equal(x.tools.length,0)});
test("registered tool is read-only without parameters",()=>{const x=setup(null);assert.equal(x.tools.length,1);assert.equal(x.tools[0].annotations.readOnlyHint,true);assert.deepEqual(Object.keys(x.tools[0].inputSchema.properties),[])});
test("successful session only returns counts, never identities or credentials",async()=>{const x=setup(result(200,{user:{email:"private@secret",token:"secret"},nodes:[{id:"owner_private",online:true},{id:"other_private",online:false}]}));const d=await x.tools[0].execute({});assert.deepEqual(Object.fromEntries(Object.entries(d)),{state:"authenticated",devices_reported:2,devices_online:1});assert(!/private|secret/i.test(JSON.stringify(d)));assert.equal(x.requests[0].url,"/api/state");assert.equal(x.requests[0].opts.credentials,"same-origin");assert.equal(x.requests[0].opts.method,"GET");assert.equal(x.requests[0].opts.redirect,"error")});
for(const status of [401,403])test(`access denial ${status} leaks no state`,async()=>{const d=await setup(result(status,{nodes:[{online:true}]})).tools[0].execute({});assert.deepEqual(Object.fromEntries(Object.entries(d)),{state:"authentication_required"})});
for(const status of [404,500,503])test(`server ${status} fails closed`,async()=>{const d=await setup(result(status,{nodes:[]})).tools[0].execute({});assert.equal(d.state,"unavailable")});
test("reject non-JSON response",async()=>{const d=await setup(result(200,{nodes:[{online:true}]},"text/html")).tools[0].execute({});assert.equal(d.state,"unavailable")});
test("reject unrecognized data shape",async()=>{const d=await setup(result(200,{user:{email:"private"}})).tools[0].execute({});assert.equal(d.state,"unavailable")});
test("network faults reveal no details",async()=>{const d=await setup(new Error("PRIVATE" )).tools[0].execute({});assert.deepEqual(Object.keys(d),["state"])});
test("zero allowed nodes returns numeric zero",async()=>{const d=await setup(result(200,{nodes:[]})).tools[0].execute({});assert.equal(d.devices_reported,0);assert.equal(d.devices_online,0)});
test("mobile website button functions even without WebMCP",async()=>{const x=setup(result(200,{nodes:[{online:true}]}),false,true);await x.listeners.click();assert.match(x.output.textContent,/1 of 1/);assert.equal(x.button.disabled,false)});
test("mobile website displays denied state",async()=>{const x=setup(result(401,{nodes:[{online:true}]}),false,true);await x.listeners.click();assert.match(x.output.textContent,/Sign in/)});
test("website page is static, no inline executable code, no indexes",()=>{const html=fs.readFileSync(path.join(__dirname,"webmcp.html"),"utf8");assert.match(html,/noindex,nofollow/);assert.match(html,/src="\\/webmcp-status.js"/);assert(!/<script>(.|\\n)*<\\/script>/i.test(html)});
