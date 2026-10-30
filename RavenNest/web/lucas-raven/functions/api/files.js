// RAVENsNEST selected-source read-only files. Original RavenNest source only.
// No legacy pairing, no cloud account federation, no provider tokens in HTML.
import {verifyAccessJwt} from './[[path]].js';
import {sealCursor,openCursor} from './file-cursor.js';
const J=(x,s=200)=>new Response(JSON.stringify(x),{status:s,headers:{'content-type':'application/json','cache-control':'private, no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer'}});
const E=(n,e)=>J({error:e},n);
const NAME=/^[a-z][a-z0-9_-]{1,48}$/,KEY=/^RAVEN_FILE_[A-Z0-9_]{2,60}$/;
const safeFile=n=>String(n||'file').replace(/[^A-Za-z0-9._ -]/g,'_').slice(0,120);
function dropboxPath(root,rel){
 if(typeof root!=='string'||typeof rel!=='string'||rel.length>1024||!rel.startsWith('/')||rel.includes('//')||rel.includes('\\')||root.includes('\\')||(root&&(!root.startsWith('/')||root.endsWith('/')||root.includes('//'))))throw Error('bad path');
 if([...root.split('/'),...rel.split('/')].some(x=>x==='.'||x==='..'||/[\u0000-\u001f\u007f]/.test(x)))throw Error('bad path');
 return root+(rel==='/'?'':rel);
}
async function principal(request,env){
 if(!env.DB)return null;
 let c;try{c=await verifyAccessJwt(request.headers.get('cf-access-jwt-assertion'),env)}catch{return null}
 if(!Number.isFinite(c.exp)||c.exp<Date.now()/1000)return null;
 const u=await env.DB.prepare('SELECT id,disabled_at FROM users WHERE subject=?1 AND email=?2').bind(c.sub,c.email).first();
 return u&&!u.disabled_at?u:null;
}
async function token(env,s){
 if(!KEY.test(s.credential_ref||''))throw Error('not configured');
 const k=s.credential_ref,rt=env[k+'_REFRESH_TOKEN'],ci=env[k+'_CLIENT_ID'],cs=env[k+'_CLIENT_SECRET'];
 if(rt&&ci){
  const endpoint=s.provider==='dropbox'?'https://api.dropbox.com/oauth2/token':'https://oauth2.googleapis.com/token';
  const body=new URLSearchParams({grant_type:'refresh_token',refresh_token:rt,client_id:ci});
  if(cs)body.set('client_secret',cs);
  const r=await fetch(endpoint,{method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},body,redirect:'error'});
  if(!r.ok)throw Error('provider unavailable');
  const j=await r.json();if(!j.access_token)throw Error('provider unavailable');return j.access_token;
 }
 if(!env[k])throw Error('not configured');
 return env[k];
}
async function remote(url,opts){
 const r=await fetch(url,{...opts,redirect:'error'});
 if(!r.ok)throw Error('provider unavailable');
 return r;
}
async function driveMeta(tok,id){
 const r=await remote('https://www.googleapis.com/drive/v3/files/'+encodeURIComponent(id)+'?fields=id,name,mimeType,parents,trashed&supportsAllDrives=true',{headers:{authorization:'Bearer '+tok}});
 return r.json();
}
async function driveScoped(tok,id,root){
 if(id===root)return true;
 let seen=new Set();
 for(let i=0;i<32;i++){
  if(seen.has(id))return false;seen.add(id);
  const d=await driveMeta(tok,id);if(d.trashed)return false;
  if((d.parents||[]).includes(root))return true;
  if((d.parents||[]).length!==1)return false;
  id=d.parents[0];
 }
 return false;
}
export async function onRequest({request,env}){
 const url=new URL(request.url),q=url.searchParams,a=q.get('action')||'providers',pageCursor=q.get('cursor');
 if(request.method!=='GET')return E(405,'method not allowed');
 if(q.toString().length>11000)return E(400,'query too long');
 if(pageCursor&&a!=='list')return E(400,'cursor only valid for listing');
 if(request.headers.get('origin')&&request.headers.get('origin')!==url.origin)return E(403,'cross-origin denied');
 const u=await principal(request,env);if(!u)return E(401,'sign-in required');
 try{
  if(a==='providers'){
   const rows=(await env.DB.prepare('SELECT s.id,s.label,s.provider,g.can_download FROM raven_file_sources s JOIN raven_file_grants g ON g.source_id=s.id WHERE s.enabled=1 AND g.user_id=?1 AND g.can_list=1 AND g.revoked_at IS NULL ORDER BY s.label LIMIT 50').bind(u.id).all()).results;
   return J({providers:rows.map(x=>({id:x.id,label:x.label,provider:x.provider,can_download:x.can_download===1}))});
  }
  if(!['list','download'].includes(a))return E(404,'not found');
  const id=q.get('source')||'';if(!NAME.test(id))return E(403,'source not permitted');
  const s=await env.DB.prepare('SELECT s.*,g.can_list,g.can_download FROM raven_file_sources s JOIN raven_file_grants g ON g.source_id=s.id WHERE s.id=?1 AND g.user_id=?2 AND g.revoked_at IS NULL AND s.enabled=1').bind(id,u.id).first();
  if(!s||s.can_list!==1||(a==='download'&&s.can_download!==1))return E(403,'source not permitted');
  if(!['dropbox','google_drive'].includes(s.provider))return E(503,'provider unsupported');
  const rel=q.get('path')||'/';if(rel.length>1024)return E(400,'invalid path');
  const scope={user:u.id,source:id,path:rel,provider:s.provider};
  let providerCursor=null;
  if(pageCursor){try{providerCursor=await openCursor(env,scope,pageCursor)}catch{return E(403,'invalid cursor')}}
  const tok=await token(env,s);
  if(s.provider==='dropbox'){
   const path=dropboxPath(s.root_ref,rel);
   if(a==='list'){
    const endpoint=providerCursor?'https://api.dropboxapi.com/2/files/list_folder/continue':'https://api.dropboxapi.com/2/files/list_folder';
    const r=await remote(endpoint,{method:'POST',headers:{authorization:'Bearer '+tok,'content-type':'application/json'},body:JSON.stringify(providerCursor?{cursor:providerCursor}:{path,recursive:false,limit:100})});
    const d=await r.json();
    const next_cursor=d.has_more?await sealCursor(env,scope,d.cursor):null;
    return J({items:(d.entries||[]).map(e=>({id:e.path_display||e.path_lower,name:e.name,type:e['.tag']==='folder'?'folder':'file',size:e.size??null})),has_more:!!d.has_more,next_cursor});
   }
   if(!path)return E(400,'file required');
   const r=await remote('https://content.dropboxapi.com/2/files/download',{method:'POST',headers:{authorization:'Bearer '+tok,'dropbox-api-arg':JSON.stringify({path})}});
   const meta=JSON.parse(r.headers.get('dropbox-api-result')||'{}');
   return new Response(r.body,{headers:{'cache-control':'private, no-store','content-type':'application/octet-stream','content-disposition':'attachment; filename="'+safeFile(meta.name||path.split('/').pop())+'"'}});
  }
  const fileId=rel==='/'?s.root_ref:rel.startsWith('/')?rel.slice(1):'';
  if(!/^[A-Za-z0-9_-]{3,200}$/.test(fileId)||!await driveScoped(tok,fileId,s.root_ref))return E(403,'outside selected Drive folder');
  if(a==='list'){
   const z=new URL('https://www.googleapis.com/drive/v3/files');
   z.searchParams.set('q',"'"+fileId+"' in parents and trashed = false");
   z.searchParams.set('fields','nextPageToken,files(id,name,mimeType,size,modifiedTime)');
   z.searchParams.set('pageSize','100');
   if(providerCursor)z.searchParams.set('pageToken',providerCursor);
   const r=await remote(z,{headers:{authorization:'Bearer '+tok}});const d=await r.json();
   const next_cursor=d.nextPageToken?await sealCursor(env,scope,d.nextPageToken):null;
   return J({items:(d.files||[]).map(e=>({id:e.id,name:e.name,type:e.mimeType==='application/vnd.google-apps.folder'?'folder':'file',size:e.size??null})),has_more:!!d.nextPageToken,next_cursor});
  }
  const m=await driveMeta(tok,fileId);if(m.mimeType==='application/vnd.google-apps.folder')return E(422,'not a file');
  const native=m.mimeType?.startsWith('application/vnd.google-apps.');
  const endpoint='https://www.googleapis.com/drive/v3/files/'+encodeURIComponent(fileId)+(native?'/export?mimeType=application%2Fpdf':'?alt=media&supportsAllDrives=true');
  const r=await remote(endpoint,{headers:{authorization:'Bearer '+tok}});
  return new Response(r.body,{headers:{'cache-control':'private, no-store','content-type':native?'application/pdf':'application/octet-stream','content-disposition':'attachment; filename="'+safeFile(m.name)+(native?'.pdf':'')+'"'}});
 }catch(e){
  if(e.message==='bad path')return E(400,'invalid path');
  if(e.message==='not configured')return E(503,'provider not configured');
  if(e.message==='cursor service not configured')return E(503,'pagination is not configured');
  return E(502,'provider unavailable');
 }
}
