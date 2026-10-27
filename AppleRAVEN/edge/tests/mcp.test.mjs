import test from 'node:test';
import assert from 'node:assert/strict';
import {handleAppleRavenMCP} from '../mcp.js';
import {onRequest} from '../functions/api/[[path]].js';
const user={id:'usr_test',role:'owner',subject:'owner@example.com',legacy:false,grants:[{device_id:'mac-a',capability:'lists.refresh'}]};
const VERSION='2026-07-28';
const metadata={'io.modelcontextprotocol/protocolVersion':VERSION,'io.modelcontextprotocol/clientCapabilities':{},'io.modelcontextprotocol/clientInfo':{name:'TestHost',version:'1.0'}};
function call(method='tools/list',params={},headers={},identity=user){const body={jsonrpc:'2.0',id:1,method,params:{_meta:metadata,...params}};
 const h={'Content-Type':'application/json','Accept':'application/json, text/event-stream','MCP-Protocol-Version':VERSION,'Mcp-Method':method,...(method==='tools/call'?{'Mcp-Name':params.name}:{}),...headers};
 const request=new Request('https://private.example/api/mcp',{method:'POST',headers:h,body:JSON.stringify(body)});
 const rows={act_0123456789abcdef0123:{id:'act_0123456789abcdef0123',node_id:'mac-a',capability:'lists.refresh',status:'succeeded',created_at:1,completed_at:2,origin:JSON.stringify({subject:'owner@example.com'}),result:'{"ok":true}'}};
 const env={DB:{prepare(q){return {bind(id){return {async first(){return rows[id]||null}}}}}}};
 return handleAppleRavenMCP({request,env,user:identity,visibleState:async()=>({ids:['mac-a'],nodes:[{node_id:'mac-a',online:false,age_s:99,meta:{hostname:'test'},state:{capabilities:{}}}]}),allowed:(_u,id,cap)=>id==='mac-a'&&cap==='lists.refresh'});
}
test('modern discovery real HTTP contract',async()=>{const r=await call('server/discover');assert.equal(r.status,200);assert.equal((await r.json()).result.supportedVersions[0],VERSION)});
test('tools list only permissioned read-only safe operations',async()=>{const r=await call();const x=(await r.json()).result.tools;assert.deepEqual(x.map(z=>z.name),['appleraven.nodes.status','appleraven.actions.status']);assert(x.every(z=>z.annotations.readOnlyHint))});
test('rejects requests without verified principal',async()=>{const r=await call('tools/list',{}, {},null);assert.equal(r.status,401)});
test('rejects legacy operator even with owner role',async()=>{const r=await call('tools/list',{}, {},{...user,legacy:true});assert.equal(r.status,401)});
test('rejects wrong origin',async()=>{const r=await call('tools/list',{}, {'Origin':'https://evil.example'});assert.equal(r.status,403)});
test('rejects protocol downgrade',async()=>{const r=await call('tools/list',{}, {'MCP-Protocol-Version':'2025-06-18'});assert.equal(r.status,400)});
test('rejects missing client meta',async()=>{const r=await call('tools/list',{_meta:{}});assert.equal(r.status,400)});
test('rejects wrong method header',async()=>{const r=await call('tools/list',{}, {'Mcp-Method':'tools/call'});assert.equal(r.status,400)});
test('filters node status by upstream authorization',async()=>{const r=await call('tools/call',{name:'appleraven.nodes.status',arguments:{}});const x=await r.json();assert(x.result.content[0].text.includes('mac-a'))});
test('reads granted action without params or credentials',async()=>{const r=await call('tools/call',{name:'appleraven.actions.status',arguments:{id:'act_0123456789abcdef0123'}});const x=await r.json();assert(x.result.content[0].text.includes('succeeded'));assert(!x.result.content[0].text.includes('params'))});
test('rejects unknown action',async()=>{const r=await call('tools/call',{name:'appleraven.actions.status',arguments:{id:'act_aaaaaaaaaaaaaaaaaaaa'}});assert.equal(r.status,404)});
test('does not expose write tools',async()=>{const r=await call('tools/call',{name:'appleraven.actions.request',arguments:{}});assert.equal(r.status,404)});

test('owner has no implicit cross-tenant device discovery',async()=>{const r=await call('tools/call',{name:'appleraven.nodes.status',arguments:{}},{},{...user,grants:[]});const x=JSON.parse((await r.json()).result.content[0].text);assert.equal(x.nodes.length,0)});
test('revoked device grant cannot read recorded action',async()=>{const r=await call('tools/call',{name:'appleraven.actions.status',arguments:{id:'act_0123456789abcdef0123'}},{},{...user,grants:[{device_id:'mac-a',capability:'lists.refresh',revoked_at:123}]});assert.equal(r.status,404)});
test('unrelated capability grant does not allow action result',async()=>{const r=await call('tools/call',{name:'appleraven.actions.status',arguments:{id:'act_0123456789abcdef0123'}},{},{...user,grants:[{device_id:'mac-a',capability:'some.other.capability'}]});assert.equal(r.status,404)});

test('original Pages router rejects unauthenticated MCP traffic before dispatch',async()=>{
 const req=new Request('https://private.example/api/mcp',{method:'POST',headers:{'content-type':'application/json','accept':'application/json, text/event-stream','MCP-Protocol-Version':VERSION,'Mcp-Method':'tools/list'},body:JSON.stringify({jsonrpc:'2.0',id:3,method:'tools/list',params:{_meta:metadata}})});
 const r=await onRequest({request:req,env:{},params:{path:['mcp']}});
 assert.equal(r.status,401);
});

test('same device and same capability never leaks another profile action',async()=>{const r=await call('tools/call',{name:'appleraven.actions.status',arguments:{id:'act_0123456789abcdef0123'}},{},{...user,subject:'other-profile'});assert.equal(r.status,404)});
