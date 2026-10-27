import {test} from 'node:test';
import assert from 'node:assert/strict';
import {handleAppleRavenMCP,VERSION} from '../mcp.js';

const META={
  'io.modelcontextprotocol/protocolVersion':'2026-07-28',
  'io.modelcontextprotocol/clientCapabilities':{}
};
const owner=()=>({id:'usr_a',subject:'verified-access-subject',role:'owner',grants:[{
  device_id:'mac-m1',capability:'photos.list',revoked_at:null
}]});
const state={ids:['mac-m1','mac-m3'],nodes:[
  {node_id:'mac-m1',online:true,age_s:2,meta:{actions:['photos.list','photos.delete']},state:{capabilities:{'photos.list':{status:'AVAILABLE'},'photos.delete':{status:'AVAILABLE'}}}},
  {node_id:'mac-m3',online:true,age_s:5,meta:{actions:['messages.read']},state:{capabilities:{'messages.read':{status:'AVAILABLE'}}}}
]};
const action={id:'act_'+'a'.repeat(20),node_id:'mac-m1',capability:'photos.list',status:'succeeded',created_at:1,completed_at:2,result:'{"ok":true}'};
const env={DB:{prepare:()=>({bind:()=>({first:async()=>action})})}};
function req(method,{name,arguments:args,meta,header={},httpMethod='POST'}={}){
 const params={_meta:{...META,...meta}};
 if(method==='tools/call'){params.name=name??'appleraven.nodes.status';params.arguments=args??{};}
 const h=new Headers({'Accept':'application/json, text/event-stream','Content-Type':'application/json',
   'MCP-Protocol-Version':VERSION,'Mcp-Method':method,...(method==='tools/call'?{'Mcp-Name':params.name}:{}),...header});
 return new Request('https://appleraven.example.test/mcp',{method:httpMethod,headers:h,
   ...(httpMethod==='POST'?{body:JSON.stringify({jsonrpc:'2.0',id:1,method,params})}:{})});
}
async function call(request,user=owner(),extra={}){return handleAppleRavenMCP({
 request,env,user,visibleState:async()=>state,allowed:()=>true,...extra
})}
test('modern discovery returns protocol version and server identity',async()=>{
 const r=await call(req('server/discover'));assert.equal(r.status,200);
 const b=await r.json();assert.deepEqual(b.result.supportedVersions,[VERSION]);
 assert.equal(b.result._meta['io.modelcontextprotocol/serverInfo'].name,'AppleRAVEN Remote');
});
test('read-only tool list has deterministic tools',async()=>{
 const b=await (await call(req('tools/list'))).json();
 assert.deepEqual(b.result.tools.map(x=>x.name),['appleraven.nodes.status','appleraven.actions.status']);
 assert.ok(b.result.tools.every(x=>x.annotations.readOnlyHint));
});
test('clientInfo is optional under final 2026 protocol',async()=>assert.equal((await call(req('tools/list'))).status,200));
test('malformed clientInfo is denied',async()=>{
 assert.equal((await call(req('tools/list',{meta:{'io.modelcontextprotocol/clientInfo':{name:'bad'}}}))).status,400);
});
test('owner MCP cannot infer access to every device or action',async()=>{
 const r=await call(req('tools/call',{name:'appleraven.nodes.status'}));
 const content=(await r.json()).result.content[0].text;
 const output=JSON.parse(content);assert.equal(output.nodes.length,1);
 assert.equal(output.nodes[0].node_id,'mac-m1');
 assert.deepEqual(Object.keys(output.nodes[0].state.capabilities),['photos.list']);
 assert.deepEqual(output.nodes[0].meta.actions,['photos.list']);
});
test('authorized action status is available',async()=>{
 const r=await call(req('tools/call',{name:'appleraven.actions.status',arguments:{id:action.id}}));
 assert.equal(r.status,200);assert.equal(JSON.parse((await r.json()).result.content[0].text).status,'succeeded');
});
test('action capability grant is always checked',async()=>{
 const r=await call(req('tools/call',{name:'appleraven.actions.status',arguments:{id:action.id}}),{
   ...owner(),grants:[{device_id:'mac-m1',capability:'photos.delete',revoked_at:null}]});
 assert.equal(r.status,404);
});
test('no user or legacy operator key is rejected',async()=>{
 assert.equal((await call(req('tools/list'),null)).status,401);
 assert.equal((await call(req('tools/list'),{...owner(),legacy:true})).status,401);
});
test('cross-origin browser call fails closed',async()=>{
 assert.equal((await call(req('tools/list',{header:{Origin:'https://attacker.example'}}))).status,403);
});
test('wrong protocol header rejected',async()=>{
 assert.equal((await call(req('tools/list',{header:{'MCP-Protocol-Version':'2025-06-18'}}))).status,400);
});
test('arbitrary effectful tools are not remotely advertised',async()=>{
 assert.equal((await call(req('tools/call',{name:'unsafe.shell',arguments:{command:'whoami'},header:{'Mcp-Name':'unsafe.shell'}}))).status,404);
});
test('invalid action identifier cannot query arbitrary rows',async()=>{
 assert.equal((await call(req('tools/call',{name:'appleraven.actions.status',arguments:{id:'bad'}}))).status,400);
});
