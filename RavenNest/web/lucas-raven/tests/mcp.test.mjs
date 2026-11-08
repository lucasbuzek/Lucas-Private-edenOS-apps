import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

globalThis.__ravenMcpFixture={calls:[]};
let source=readFileSync(new URL('../functions/mcp.js',import.meta.url)).toString();
source=source.replace("import {onRequest as filesRequest} from './api/files.js';",`
const filesRequest=async ({request})=>{
 const u=new URL(request.url);
 globalThis.__ravenMcpFixture.calls.push({path:u.pathname,query:u.search,auth:request.headers.get('cf-access-jwt-assertion'),origin:request.headers.get('origin')});
 if(request.headers.get('cf-access-jwt-assertion')!=='approved')return new Response(JSON.stringify({error:'sign-in required'}),{status:401});
 const action=u.searchParams.get('action');
 if(action==='providers')return new Response(JSON.stringify({providers:[{id:'research',label:'Approved Dropbox',provider:'dropbox',can_download:true}]}),{status:200});
 if(u.searchParams.get('source')!=='research')return new Response(JSON.stringify({error:'source not permitted'}),{status:403});
 return new Response(JSON.stringify({items:[{id:'/report.txt',name:'report.txt',type:'file'}],has_more:false,next_cursor:null}),{status:200});
};
`);
const {onRequest}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
const META={'io.modelcontextprotocol/protocolVersion':'2026-07-28','io.modelcontextprotocol/clientInfo':{name:'test',version:'1.0'},'io.modelcontextprotocol/clientCapabilities':{}};
const payload=(method,params={},id=1)=>({jsonrpc:'2.0',id,method,params:{...params,_meta:META}});
function request(body,{modern=true,auth='approved',origin=null,method='POST',overrides={}}={}){
 const headers={'content-type':'application/json',...(auth?{'cf-access-jwt-assertion':auth}:{})};
 if(origin)headers.origin=origin;
 if(modern){headers['mcp-protocol-version']='2026-07-28';headers['mcp-method']=body.method;if(body.method==='tools/call')headers['mcp-name']=body.params?.name||''}
 Object.assign(headers,overrides);
 return new Request('https://raven.example/mcp',{method,headers,...(method==='POST'?{body:JSON.stringify(body)}:{})});
}
async function call(body,opts){return onRequest({request:request(body,opts),env:{DB:{}}})}
test.beforeEach(()=>{globalThis.__ravenMcpFixture.calls=[]});

test('MCP is fail-closed for unauthenticated clients',async()=>{
 const r=await call(payload('server/discover'),{auth:null});
 assert.equal(r.status,401);
 assert.equal((await r.json()).error.code,-32001);
});
test('modern discovery reports stateless supported versions, not private data',async()=>{
 const r=await call(payload('server/discover'));
 assert.equal(r.status,200);
 const result=(await r.json()).result;
 assert.equal(result.resultType,'complete');
 assert.deepEqual(result.supportedVersions,['2026-07-28','2025-11-25']);
 assert.equal(result.cacheScope,'private');
 assert.ok(!JSON.stringify(result).includes('Approved Dropbox'));
});
test('tool list advertises only the two read-only tools',async()=>{
 const r=await call(payload('tools/list'));
 assert.equal(r.status,200);
 const result=(await r.json()).result;
 assert.deepEqual(result.tools.map(x=>x.name),['raven_files_providers','raven_files_list']);
 assert.ok(result.tools.every(x=>x.annotations.readOnlyHint===true));
 assert.equal(result.ttlMs,0);
});
test('approved MCP provider listing delegates to original authorization API',async()=>{
 const r=await call(payload('tools/call',{name:'raven_files_providers',arguments:{}}));
 assert.equal(r.status,200);
 const x=(await r.json()).result;
 assert.equal(x.resultType,'complete');
 assert.equal(x.isError,false);
 assert.equal(x.structuredContent.providers[0].id,'research');
 assert.ok(globalThis.__ravenMcpFixture.calls.every(c=>c.auth==='approved'&&c.origin===null));
});
test('MCP folder listing delegates source grants and reports denied sources',async()=>{
 const ok=await call(payload('tools/call',{name:'raven_files_list',arguments:{source:'research',path:'/'}}));
 assert.equal((await ok.json()).result.structuredContent.items[0].name,'report.txt');
 const denied=await call(payload('tools/call',{name:'raven_files_list',arguments:{source:'ungranted'}}));
 const output=(await denied.json()).result;
 assert.equal(output.isError,true);
 assert.equal(output.structuredContent.error,'source not permitted');
});
test('tool calls reject extra keys, missing source and private credential inputs',async()=>{
 for(const args of [{},{source:'research',unapproved:true},{source:'research',credential:'abc'}, {source:'../../etc'}]){
  const r=await call(payload('tools/call',{name:'raven_files_list',arguments:args}));
  assert.equal(r.status,400);
  assert.equal((await r.json()).error.code,-32602);
 }
});
test('origin and MCP header mismatches are denied',async()=>{
 assert.equal((await call(payload('tools/list'),{origin:'https://evil.example'})).status,403);
 assert.equal((await call(payload('tools/list'),{overrides:{'mcp-method':'tools/call'}})).status,400);
 assert.equal((await call(payload('tools/call',{name:'raven_files_providers',arguments:{}}),{overrides:{'mcp-name':'different'}})).status,400);
});
test('2025-11-25 handshake fallback remains available under signed-in identity',async()=>{
 const init={jsonrpc:'2.0',id:2,method:'initialize',params:{protocolVersion:'2025-11-25',capabilities:{},clientInfo:{name:'legacy-test',version:'1'}}};
 const r=await call(init,{modern:false});
 assert.equal(r.status,200);
 assert.equal((await r.json()).result.protocolVersion,'2025-11-25');
 const legacy=await call({jsonrpc:'2.0',id:3,method:'tools/list',params:{}},{modern:false});
 assert.equal((await legacy.json()).result.tools.length,2);
});
test('unexpected RPC method, unsupported version, method and content type fail',async()=>{
 assert.equal((await call(payload('tools/delete'))).status,404);
 assert.equal((await call(payload('tools/list'),{overrides:{'mcp-protocol-version':'9999-99-99'}})).status,400);
 assert.equal((await call(payload('tools/list'),{method:'GET'})).status,405);
 assert.equal((await call(payload('tools/list'),{overrides:{'content-type':'text/plain'}})).status,415);
});
