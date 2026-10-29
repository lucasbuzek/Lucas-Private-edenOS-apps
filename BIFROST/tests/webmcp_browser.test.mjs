import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
import test from 'node:test';
import vm from 'node:vm';
const code=readFileSync(new URL('../headless/webmcp.js',import.meta.url),'utf8');
function harness(enabled=true) {
  const slots=new Map([
    ['webmcpEnable',{handlers:{},addEventListener(s,f){this.handlers[s]=f}}],
    ['webmcpRevoke',{handlers:{},addEventListener(s,f){this.handlers[s]=f}}],
    ['webmcpState',{textContent:''}]
  ]);
  let init;
  const calls=[],items=[];
  const window={handlers:{},addEventListener(s,f){this.handlers[s]=f}};
  const document={
    getElementById:id=>slots.get(id),
    addEventListener(s,f){init=f},
    modelContext:enabled?{async registerTool(tool,options){items.push({tool,options})}}:null
  };
  const fetch=async (path,options)=>{
    calls.push({path,options});
    return {ok:true,json:async()=>path.endsWith('tools')?{
      tools:[{name:'bifrost.connection.health.read',description:'Local health',
              annotations:{readOnlyHint:true}},{name:'danger',annotations:{readOnlyHint:false}}]
    }:{content:[{type:'text',text:'observed'}],isError:false}};
  };
  const ctx=vm.createContext({document,window,fetch,token:'owner-session',AbortController,JSON,Error,Object,Array});
  vm.runInContext(code,ctx);init();
  return {slots,items,calls,window,ctx};
}
test('browser WebMCP registers a callable original BIFROST tool only on opt-in',async()=>{
  const h=harness();assert.equal(h.items.length,0);
  await h.slots.get('webmcpEnable').handlers.click();
  assert.equal(h.items.length,1);
  assert.equal(h.items[0].tool.name,'bifrost_bifrost_connection_health_read');
  assert.equal((await h.items[0].tool.execute({})).content[0].text,'observed');
  assert.equal(h.calls.at(-1).path,'/api/webmcp/call');
  assert.equal(h.calls.at(-1).options.headers['X-Bifrost-Token'],'owner-session');
});
test('revoke cancels and blocks subsequent browser tool invocations',async()=>{
  const h=harness();await h.slots.get('webmcpEnable').handlers.click();
  const before=h.calls.length;
  h.slots.get('webmcpRevoke').handlers.click();
  assert.equal(h.items[0].options.signal.aborted,true);
  assert.equal((await h.items[0].tool.execute({})).isError,true);
  assert.equal(h.calls.length,before);
});
test('unsupported browser and unapproved arguments fail closed',async()=>{
  const h=harness(false);await h.slots.get('webmcpEnable').handlers.click();
  assert.equal(h.items.length,0);
  const h2=harness();await h2.slots.get('webmcpEnable').handlers.click();
  const calls=h2.calls.length;
  assert.equal((await h2.items[0].tool.execute({command:'not approved'})).isError,true);
  assert.equal(h2.calls.length,calls);
});
