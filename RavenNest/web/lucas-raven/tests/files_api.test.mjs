import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {webcrypto} from 'node:crypto';
globalThis.crypto ??= webcrypto;

// Load the exact Pages function source; only inject an isolated identity verifier.
// All file-path/grant/provider logic remains original production source.
const cursor = readFileSync(new URL('../functions/api/file-cursor.js',import.meta.url)).toString();
const cursorUrl = 'data:text/javascript;base64,' + Buffer.from(cursor).toString('base64');
let code = readFileSync(new URL('../functions/api/files.js',import.meta.url)).toString();
code = code.replace("import {verifyAccessJwt} from './[[path]].js';",
 "const verifyAccessJwt=async token => { if(token!=='approved' && token!=='expired') throw Error('unauthorized'); return {sub:'owner-sub',email:'owner@example.test',exp:token==='expired'?1:Date.now()/1000+3600}; };")
 .replace("import {sealCursor,openCursor} from './file-cursor.js';",
 "import {sealCursor,openCursor} from '"+cursorUrl+"';");
const {onRequest} = await import('data:text/javascript;base64,' + Buffer.from(code).toString('base64'));

const selected={id:'research',label:'Selected Dropbox',provider:'dropbox',root_ref:'/',credential_ref:'RAVEN_FILE_GOOD',enabled:1,can_list:1,can_download:1};
const drive={...selected,id:'drive',label:'Selected Drive',provider:'google_drive',root_ref:'root123'};
function environment(overrides={}){
 const rows=[selected,drive];
 return {
  RAVEN_FILES_CURSOR_KEY:'isolated-test-cursor-key-at-least-32-characters',
  RAVEN_FILE_GOOD:'isolated-test-provider-token',
  DB:{
   prepare(sql){
    let args=[];
    return {
     bind(...a){args=a;return this},
     async first(){
      if(sql.includes('FROM users'))return args[0]==='owner-sub'&&args[1]==='owner@example.test'?{id:'owner',disabled_at:null}:null;
      if(sql.includes('FROM raven_file_sources'))return rows.find(x=>x.id===args[0])||null;
      throw Error('Unexpected SQL '+sql);
     },
     async all(){
      if(sql.includes('FROM raven_file_sources'))return {results:rows.map(x=>({id:x.id,label:x.label,provider:x.provider,can_download:x.can_download}))};
      throw Error('Unexpected SQL '+sql);
     }
    }
   }
  },
  ...overrides
 };
}
function req(query={},options={}){
 const url=new URL('https://raven.example/api/files');
 for(const [k,v] of Object.entries(query))url.searchParams.set(k,v);
 const h=new Headers(options.headers||{});
 if(options.auth!==false)h.set('cf-access-jwt-assertion',options.auth||'approved');
 return new Request(url,{method:options.method||'GET',headers:h});
}
async function response(query,options={},env=environment()){return onRequest({request:req(query,options),env})}
function mockDropbox({has_more=false}={}){
 const seen=[];
 globalThis.fetch=async (url,opts)=>{
  seen.push({url:String(url),options:opts});
  if(String(url).includes('dropboxapi.com/2/files/list_folder')){
   return new Response(JSON.stringify({entries:[{'.tag':'file',name:'report.txt',path_display:'/report.txt',size:5}],has_more,cursor:'provider-private-continuation-token'}),{status:200,headers:{'content-type':'application/json'}});
  }
  if(String(url).includes('content.dropboxapi.com')){
   return new Response('hello',{status:200,headers:{'dropbox-api-result':JSON.stringify({name:'report.txt'})}});
  }
  throw Error('Unexpected provider request '+url);
 };
 return seen;
}
const originalFetch=globalThis.fetch;
test.afterEach(()=>{globalThis.fetch=originalFetch});

test('unauthenticated and expired identities are rejected before provider access',async()=>{
 const seen=mockDropbox();
 assert.equal((await response({action:'list',source:'research'},{auth:false})).status,401);
 assert.equal((await response({action:'list',source:'research'},{auth:'expired'})).status,401);
 assert.equal(seen.length,0);
});
test('approved source list is scoped to the enrolled user',async()=>{
 const r=await response({action:'providers'});
 assert.equal(r.status,200);
 const j=await r.json();
 assert.deepEqual(j.providers.map(x=>x.id),['research','drive']);
});
test('ungranted source and disabled download fail before provider access',async()=>{
 const seen=mockDropbox();
 assert.equal((await response({action:'list',source:'other'})).status,403);
 const env=environment();
 const original=env.DB.prepare.bind(env.DB);
 env.DB.prepare=sql=>{
  const s=original(sql);
  if(sql.includes('SELECT s.*,g.can_list'))s.first=async()=>({...selected,can_download:0});
  return s;
 };
 assert.equal((await response({action:'download',source:'research',path:'/report.txt'},{},env)).status,403);
 assert.equal(seen.length,0);
});
test('Dropbox root grant lists root without a double slash',async()=>{
 const seen=mockDropbox();
 const r=await response({action:'list',source:'research',path:'/'});
 assert.equal(r.status,200);
 assert.equal((await r.json()).items[0].name,'report.txt');
 assert.equal(JSON.parse(seen[0].options.body).path,'');
});
test('Dropbox pagination hides provider cursor and rejects folder replay',async()=>{
 const seen=mockDropbox({has_more:true});
 const first=await response({action:'list',source:'research',path:'/'});
 assert.equal(first.status,200);
 const j=await first.json();
 assert.equal(j.has_more,true);
 assert.ok(j.next_cursor.startsWith('v2.'));
 assert.ok(!j.next_cursor.includes('provider-private-continuation-token'));
 const resume=await response({action:'list',source:'research',path:'/',cursor:j.next_cursor});
 assert.equal(resume.status,200);
 assert.equal(JSON.parse(seen[1].options.body).cursor,'provider-private-continuation-token');
 assert.equal((await response({action:'list',source:'research',path:'/other',cursor:j.next_cursor})).status,403);
});
test('path traversal, cross origin and unsafe method are denied',async()=>{
 mockDropbox();
 assert.equal((await response({action:'list',source:'research',path:'/../secrets'})).status,400);
 assert.equal((await response({action:'list',source:'research'},{headers:{origin:'https://evil.example'}})).status,403);
 assert.equal((await response({action:'list',source:'research'},{method:'POST'})).status,405);
});
test('approved Dropbox file download is streamed with a safe attachment name',async()=>{
 mockDropbox();
 const r=await response({action:'download',source:'research',path:'/report.txt'});
 assert.equal(r.status,200);
 assert.match(r.headers.get('content-disposition'),/report.txt/);
 assert.equal(await r.text(),'hello');
});
test('unconfigured provider secret fails closed',async()=>{
 const seen=mockDropbox();
 const env=environment({RAVEN_FILE_GOOD:null});
 assert.equal((await response({action:'list',source:'research'},{},env)).status,503);
 assert.equal(seen.length,0);
});
test('Google Drive rejects IDs outside the selected root and lists granted root',async()=>{
 const seen=[];
 globalThis.fetch=async(url)=>{
  seen.push(String(url));
  if(String(url).includes('/files/root123?'))return new Response(JSON.stringify({id:'root123',name:'Root',parents:[],mimeType:'application/vnd.google-apps.folder'}));
  if(String(url).includes('/files/outsider?'))return new Response(JSON.stringify({id:'outsider',name:'Private',parents:['other-root'],mimeType:'application/vnd.google-apps.folder'}));
  if(String(url).includes('/files/other-root?'))return new Response(JSON.stringify({id:'other-root',name:'Outside',parents:[],mimeType:'application/vnd.google-apps.folder'}));
  if(String(url).includes('/drive/v3/files?'))return new Response(JSON.stringify({files:[{id:'child123',name:'Child',mimeType:'text/plain'}]}));
  throw Error('Unexpected Drive request '+url);
 };
 const ok=await response({action:'list',source:'drive',path:'/'});
 assert.equal(ok.status,200);
 assert.equal((await ok.json()).items[0].id,'child123');
 const no=await response({action:'list',source:'drive',path:'/outsider'});
 assert.equal(no.status,403);
 assert.ok(seen.some(x=>x.includes('/files/outsider?')));
});
