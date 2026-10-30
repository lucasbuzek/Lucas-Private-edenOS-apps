"use strict";
// RAVENsNEST human-first file browser; WebMCP is optional on supported browsers.
(()=>{
 const $=id=>document.getElementById(id);
 let sources=[],source=null,paths=['/'],busy=0,nextCursor=null,shown=0;
 const say=s=>{$('status').textContent=s};
 async function api(data){
  const u=new URL('/api/files',location.origin);
  for(const [k,v] of Object.entries(data))if(v!==null&&v!==undefined)u.searchParams.set(k,v);
  const r=await fetch(u.pathname+u.search,{credentials:'same-origin',cache:'no-store',redirect:'error',headers:{accept:'application/json'}});
  const j=await r.json().catch(()=>({}));
  if(!r.ok)throw Error(r.status===401?'Sign in to the protected portal.':r.status===403?'Access denied.':j.error||'Unavailable');
  return j;
 }
 function element(tag,value){const e=document.createElement(tag);if(value!==undefined)e.textContent=value;return e}
 function start(){paths=['/'];nextCursor=null;shown=0;$('up').disabled=true;refresh()}
 async function sourcesList(){
  say('Checking authorized sources…');
  try{
   const j=await api({action:'providers'});sources=j.providers||[];
   $('source').replaceChildren(...sources.map(s=>{const e=element('option',s.label+' · '+s.provider);e.value=s.id;return e}));
   if(!sources.length){source=null;$('items').replaceChildren();say('No approved providers. Connect a storage account and grant access first.');return}
   source=sources[0];$('source').value=source.id;start();
  }catch(e){say(e.message);$('items').replaceChildren()}
 }
 async function refresh(cursor=null){
  if(!source)return;
  const seq=++busy,at=paths[paths.length-1],paging=typeof cursor==='string'&&cursor.length>0;
  $('more').disabled=true;say(paging?'Loading next page…':'Loading files…');
  try{
   const result=await api({action:'list',source:source.id,path:at,cursor:paging?cursor:null});
   if(seq!==busy)return;
   const rows=(result.items||[]).map(item=>{
    const r=element('div');r.className='file-row';
    const name=element('span',(item.type==='folder'?'▣ ':'▤ ')+item.name);name.className='file-name';
    const b=element('button',item.type==='folder'?'Open':'Download');b.type='button';
    b.onclick=()=>{
     if(item.type==='folder'){
      paths.push(source.provider==='dropbox'?(at==='/'?'/'+item.name:at+'/'+item.name):'/'+item.id);
      nextCursor=null;shown=0;$('up').disabled=false;refresh();return;
     }
     const u=new URL('/api/files',location.origin);
     u.searchParams.set('action','download');u.searchParams.set('source',source.id);
     u.searchParams.set('path',source.provider==='dropbox'?(at==='/'?'/'+item.name:at+'/'+item.name):'/'+item.id);
     const a=element('a');a.href=u.pathname+u.search;a.download=item.name;a.rel='noopener';a.click();
    };
    r.append(name,b);return r;
   });
   if(paging)$('items').append(...rows);else $('items').replaceChildren(...rows);
   shown=paging?shown+rows.length:rows.length;
   nextCursor=typeof result.next_cursor==='string'?result.next_cursor:null;
   $('more').hidden=!nextCursor;$('more').disabled=false;
   $('location').textContent=at;
   say(shown+' files and folders'+(nextCursor?' · more available':result.has_more?' · pagination is not configured':''));
  }catch(e){if(seq===busy){say(e.message);$('more').disabled=false;if(!paging){$('items').replaceChildren();$('more').hidden=true;nextCursor=null}}}
 }
 $('source').addEventListener('change',()=>{source=sources.find(s=>s.id===$('source').value);start()});
 $('refresh').addEventListener('click',()=>source?refresh():sourcesList());
 $('up').addEventListener('click',()=>{if(paths.length>1){paths.pop();nextCursor=null;shown=0;$('up').disabled=paths.length===1;refresh()}});
 $('more').hidden=true;
 $('more').addEventListener('click',()=>{if(nextCursor&&!$('more').disabled)refresh(nextCursor)});
 if(document.modelContext&&typeof document.modelContext.registerTool==='function'){
  document.modelContext.registerTool({
   name:'raven_files_providers',description:'List only the storage sources granted to the signed-in portal account; no secrets.',
   inputSchema:{type:'object',properties:{},additionalProperties:false},
   annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false},
   execute:()=>api({action:'providers'})
  });
  document.modelContext.registerTool({
   name:'raven_files_list',description:'List an approved source folder under the same server-side user grants.',
   inputSchema:{type:'object',properties:{source:{type:'string'},path:{type:'string'},cursor:{type:'string'}},required:['source'],additionalProperties:false},
   annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false},
   execute:({source,path,cursor})=>api({action:'list',source,path:path||'/',cursor:cursor||null})
  });
 }
 sourcesList();
})();