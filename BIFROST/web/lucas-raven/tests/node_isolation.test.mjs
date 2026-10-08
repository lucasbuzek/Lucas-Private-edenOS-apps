import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { webcrypto } from 'node:crypto';
if (!crypto.subtle.timingSafeEqual) crypto.subtle.timingSafeEqual = (a,b) => Buffer.from(a).equals(Buffer.from(b));
const src = readFileSync(new URL('../functions/api/[[path]].js', import.meta.url), 'utf8');
const api = await import('data:text/javascript;base64,' + Buffer.from(src).toString('base64'));
test('result updates are restricted to authenticated node identity', async () => {
  const calls = [];
  const db = { prepare(sql) { return { bind(...args) {
    calls.push({sql,args});
    return {async run() {return {meta:{changes:0}};}};
  }}; }};
  const req = new Request('https://example.invalid/api/node/result', {
    method:'POST', headers:{authorization:'Bearer ' + 'a'.repeat(48),'content-type':'application/json'},
    body: JSON.stringify({node_id:'node-b',id:'act_'+'a'.repeat(20),ok:true,result:{}})
  });
  const digest = await crypto.subtle.digest('SHA-256',new TextEncoder().encode('a'.repeat(48)));
  const hex = Buffer.from(digest).toString('hex');
  const res = await api.onRequest({request:req,env:{DB:db,NODE_KEY_SHA256:hex},params:{path:['node','result']}});
  assert.equal(res.status,409);
  assert.equal(calls.length,1);
  assert.match(calls[0].sql,/node_id=\?5 AND status='claimed'/);
  assert.equal(calls[0].args[4],'node-b');
});
test('result rejects missing node identity before updating actions', async () => {
  const key='b'.repeat(48);
  const hex=Buffer.from(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(key))).toString('hex');
  const req=new Request('https://example.invalid/api/node/result',{method:'POST',headers:{authorization:'Bearer '+key},body:JSON.stringify({id:'act_'+'a'.repeat(20),ok:true})});
  const res=await api.onRequest({request:req,env:{NODE_KEY_SHA256:hex,DB:{}},params:{path:['node','result']}});
  assert.equal(res.status,400);
});
