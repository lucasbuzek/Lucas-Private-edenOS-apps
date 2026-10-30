"use strict";
// Original RavenNest add-on: progressive, browser-standard and mobile Safari compatible.
(()=>{
 const $=id=>document.getElementById(id),el=(tag,txt)=>{const n=document.createElement(tag);if(txt!==undefined)n.textContent=txt;return n};
 let offset=0,query='',loading=false;
 const status=(msg)=>{$('status').textContent=msg};
 async function api(method,queryParams={},body){
  const url=new URL('/api/knowledge',location.origin);
  for(const [k,v] of Object.entries(queryParams))if(v!==undefined)url.searchParams.set(k,String(v));
  const r=await fetch(url.pathname+url.search,{method,credentials:'same-origin',cache:'no-store',redirect:'error',headers:body?{'content-type':'application/json','accept':'application/json'}:{'accept':'application/json'},body:body?JSON.stringify(body):undefined});
  const j=await r.json().catch(()=>({}));
  if(!r.ok)throw Error(r.status===401?'Sign in to RAVENsNEST to access your library.':r.status===403?'Access denied.':j.error||'Library unavailable');
  return j;
 }
 function render(item){
  const article=el('article');article.className='knowledge-row';const title=el('h3',item.title),desc=el('p',item.description||'No description yet.'),meta=el('div');meta.className='knowledge-badges';
  for(const tag of [item.site,item.kind,item.taxonomy_namespace&&item.taxonomy_namespace!=='unclassified'?item.taxonomy_namespace:null,item.review_status])if(tag)meta.appendChild(el('span',tag));
  const link=el('a','Read original source');link.className='knowledge-link';link.href=item.url;link.target='_blank';link.rel='noopener noreferrer';link.referrerPolicy='no-referrer';
  article.append(title,desc,meta,link);return article;
 }
 async function read(reset){
  if(loading)return;loading=true;if(reset){offset=0;$('entries').replaceChildren()};status('Loading authorized resources…');$('more').hidden=true;
  try{
   const r=await api('GET',{action:'list',q:query,offset,limit:30});
   for(const item of r.items||[])$('entries').appendChild(render(item));
   offset=r.next_offset||0;$('more').hidden=r.next_offset===null;
   status($('entries').children.length+' sources in your authorized view'+(r.next_offset!==null?' (more available)':''));
  }catch(e){status(e.message)}finally{loading=false}
 }
 $('search-form').addEventListener('submit',e=>{e.preventDefault();query=$('search').value.trim();read(true)});
 $('more').addEventListener('click',()=>read(false));
 $('add-form').addEventListener('submit',async e=>{
  e.preventDefault();const form=e.currentTarget,button=form.querySelector('button[type="submit"]'),data=Object.fromEntries(new FormData(form));button.disabled=true;$('add-status').textContent='Saving privately…';
  try{await api('POST',{},data);form.reset();$('add-status').textContent='Saved privately. The link is now in your library.';await read(true)}catch(err){$('add-status').textContent=err.message}finally{button.disabled=false}
 });
 if(document.modelContext&&typeof document.modelContext.registerTool==='function'){
  document.modelContext.registerTool({name:'raven_knowledge_search',description:'Search source titles and descriptions visible to this signed-in user. Does not retrieve other users’ collections or secret credentials.',inputSchema:{type:'object',properties:{query:{type:'string',description:'Words in source title, summary, source name or category label.',maxLength:120}},required:['query'],additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false},execute:({query})=>api('GET',{action:'list',q:String(query).slice(0,120),limit:30})});
 }
 read(true);
})();
