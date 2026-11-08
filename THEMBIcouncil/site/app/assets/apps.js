
'use strict';
const api='/app/api/',byId=id=>document.getElementById(id),kind=()=>document.body.dataset.app||'';
let currentUser=null,items=[],chosenId=null;
function setMessage(message,err=false){const e=byId('message');if(e){e.textContent=message;e.classList.toggle('err',err)}}
async function request(url,method='GET',body){
 const options={method,credentials:'same-origin',headers:{'Accept':'application/json',...(body?{'Content-Type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{})};
 const res=await fetch(api+url,options);const data=await res.json().catch(()=>({error:'invalid_server_response'}));
 if(!res.ok)throw Error(data.error||('HTTP '+res.status));return data;
}
async function loadItems(which){const resp=await request('items'+(which?'?kind='+encodeURIComponent(which):''));items=resp.items||[];return items}
function escapeText(str){const n=document.createElement('span');n.textContent=String(str);return n.innerHTML}
function node(tag,className,text){const e=document.createElement(tag);if(className)e.className=className;if(text!==undefined)e.textContent=text;return e}
function emptyNote(el,text='Nothing saved yet.'){el.replaceChildren(node('p','muted',text))}
function renderItems(){
 const e=byId('items');if(!e)return;e.replaceChildren();if(!items.length){emptyNote(e,kind()==='tasks'?'Add your first task.':'Add your first document.');return}
 for(const item of items){
  const row=node('article','item'+(item.done?' completed':''));row.dataset.id=item.id;
  const content=node('div');content.style.minWidth='0';content.append(node('h3','',item.title));if(item.body)content.append(node('p','',item.body.slice(0,500)));
  const actions=node('div','item-actions');
  if(item.kind==='task'){const tick=node('button','tiny',item.done?'Reopen':'Done');tick.type='button';tick.addEventListener('click',()=>patchItem(item,{done:!item.done}));actions.append(tick)}
  else{const open=node('button','tiny','Open');open.type='button';open.addEventListener('click',()=>{chosenId=item.id;byId('item-title').value=item.title;byId('item-body').value=item.body;byId('save-item').textContent='Save changes';byId('edit-heading')&&(byId('edit-heading').textContent='Edit document');byId('item-title').focus()});actions.append(open)}
  const del=node('button','tiny','Delete');del.type='button';del.addEventListener('click',async()=>{if(!confirm('Delete this item?'))return;try{await request('items','DELETE',{id:item.id,version:item.version,confirm:true});setMessage('Deleted.');await refresh()}catch(err){setMessage(err.message,true)}});actions.append(del);
  row.append(content,actions);e.append(row)
 }
}
async function patchItem(item,body){try{await request('items','PATCH',{id:item.id,version:item.version,...body});setMessage('Saved.');await refresh()}catch(e){setMessage(e.message,true)}}
async function refresh(){
 const k=kind();if(k==='tasks')await loadItems('task');else if(['storage','documents'].includes(k))await loadItems(k==='storage'?'file':'note');renderItems();
}
function installEditors(){
 const k=kind(),form=byId('item-form');if(form){
 form.addEventListener('submit',async e=>{e.preventDefault();let title=byId('item-title').value.trim(),body=byId('item-body')?.value||'';if(!title)return;try{
  if(chosenId){const prev=items.find(x=>x.id===chosenId);if(!prev)throw Error('Item changed; refresh first');await request('items','PATCH',{id:chosenId,version:prev.version,title,body})}
  else await request('items','POST',{kind:k==='tasks'?'task':k==='storage'?'file':'note',title,body});
  chosenId=null;form.reset();byId('save-item').textContent=k==='tasks'?'Add task':'Save';setMessage('Saved securely to your personal workspace.');await refresh();
 }catch(err){setMessage(err.message,true)}})}
 const picker=byId('file-upload');if(picker)picker.addEventListener('change',async()=>{const file=picker.files?.[0];if(!file)return;if(file.size>60000){setMessage('For this release, select a text document under 60 KB.',true);return}if(!/\.(txt|md|csv|json|log)$/i.test(file.name)&&!file.type.startsWith('text/')){setMessage('Text documents only. Use your existing cloud provider for other files.',true);return}
 try{const body=await file.text();await request('items','POST',{kind:'file',title:file.name.slice(0,180),body});setMessage('Imported '+file.name+' into your personal cloud documents.');await refresh()}catch(err){setMessage(err.message,true)}})
 const download=byId('download-item');if(download)download.addEventListener('click',()=>{const content=byId('item-body')?.value||'';const title=(byId('item-title')?.value||'document').replace(/[^a-zA-Z0-9._-]/g,'_').slice(0,90);const u=URL.createObjectURL(new Blob([content],{type:'text/plain'}));const a=document.createElement('a');a.href=u;a.download=title.endsWith('.txt')?title:title+'.txt';a.click();setTimeout(()=>URL.revokeObjectURL(u),5000)})
 const clear=byId('new-item');if(clear)clear.addEventListener('click',()=>{chosenId=null;form?.reset();byId('save-item')&&(byId('save-item').textContent='Save')});
}
function addMessage(text,isMe=false){const area=byId('chatlog');if(!area)return;area.append(node('div','msg'+(isMe?' me':''),text));area.scrollTop=area.scrollHeight}
async function assistant(input){
 const q=input.trim();if(!q)return;
 const add=q.match(/^(?:add|create|remind me to)\s+(?:a\s+)?task[:\s]+(.+)$/i)||q.match(/^remind me to\s+(.+)$/i);
 const note=q.match(/^(?:remember|save a note|note)[:\s]+(.+)$/i);
 if(add){const title=add[1].trim();if(title.length>180)return 'Please shorten that task.';await request('items','POST',{kind:'task',title,body:''});return 'Added to your personal Tasks: '+title}
 if(note){const body=note[1].trim();await request('items','POST',{kind:'note',title:body.slice(0,80),body});return 'Saved as a personal note.'}
 if(/\b(show|list|what|find)\b.*\b(tasks|to dos|todo)\b/i.test(q)){const {items}=await request('items?kind=task');return items.length?'Your tasks:\n'+items.slice(0,20).map(x=>(x.done?'✓ ':'• ')+x.title).join('\n'):'Your task list is empty.'}
 if(/\b(show|list|find)\b.*\b(notes|documents)\b/i.test(q)){const {items}=await request('items?kind=note');return items.length?'Your notes:\n'+items.slice(0,20).map(x=>'• '+x.title).join('\n'):'You have no saved notes yet.'}
 if(/\b(storage|files|drive|iCloud)\b/i.test(q))return 'You can work with selected files in Storage. Open the Storage app from the app directory. iCloud access remains under your own Apple login.';
 if(/\b(hello|hi|hey)\b/i.test(q))return 'Hello, '+(currentUser?.display_name||'there')+'. I can organize tasks, remember notes, and find what you saved. What would you like to do?';
 try{const result=await request('agent','POST',{message:q,persona:byId('council-persona')?.value||'Heartbi'});return result.reply}catch(e){if(e.message==='agent_runtime_not_connected')return 'Council AI has not been connected to a personal agent engine yet. Your tasks and notes are still available.';return 'Council AI request was not completed ('+e.message+'). Check the individual action receipts before retrying commands that could change files.'}
}
function initAssistant(){
 const form=byId('assistant-form');if(!form)return;
 addMessage('Hi '+(currentUser?.display_name||'there')+'. I can help with tasks and notes. Ask me to add or find something.');
 form.addEventListener('submit',async e=>{e.preventDefault();const field=byId('assistant-input');const q=field.value.trim();if(!q)return;field.value='';addMessage(q,true);try{addMessage(await assistant(q))}catch(err){addMessage('I could not complete that action: '+err.message)}});
}
function initCatalog(){
 const search=byId('search-app'),filters=[...document.querySelectorAll('[data-filter]')],cards=[...document.querySelectorAll('[data-app-card]')];if(!search)return;let category='all';
 function paint(){const q=search.value.toLowerCase().trim();for(const card of cards){const ok=(category==='all'||(card.dataset.category||'').split(' ').includes(category))&&(!q||card.textContent.toLowerCase().includes(q));card.hidden=!ok}}
 search.addEventListener('input',paint);for(const filter of filters)filter.addEventListener('click',()=>{category=filter.dataset.filter;for(const f of filters)f.setAttribute('aria-pressed',String(f===filter));paint()})
}
function initLocalView(){
 const picker=byId('local-preview');if(picker)picker.addEventListener('change',async()=>{const f=picker.files?.[0],out=byId('preview');if(!f||!out)return;if(f.type.startsWith('image/')){out.replaceChildren();const img=node('img','img-preview');img.alt='Selected image preview';const u=URL.createObjectURL(f);img.src=u;img.onload=()=>setTimeout(()=>URL.revokeObjectURL(u),10000);out.append(img)}
 else if(f.type==='application/pdf'||f.name.toLowerCase().endsWith('.pdf')){out.replaceChildren();const frame=node('iframe');frame.id='pdf-preview';frame.title='Selected PDF preview';const u=URL.createObjectURL(f);frame.src=u;out.append(frame)}
 else if(f.size<=60000){out.textContent=await f.text()}else out.textContent='This file cannot be previewed here; try opening it in its dedicated app.'});
 const maps=byId('maps-go');if(maps)maps.addEventListener('click',()=>{const q=byId('maps-query').value.trim();if(q)window.open('https://maps.apple.com/?q='+encodeURIComponent(q),'_blank','noopener,noreferrer')})
}
(async()=>{
 try{
  const response=await request('me');if(!response.authenticated)throw Error('not signed in');
  currentUser=response;const pill=byId('account-name');if(pill){pill.textContent=response.display_name+(response.role==='owner_admin'?' · Owner':' · Administrator');const signout=node('button','tiny','Sign out');signout.type='button';signout.addEventListener('click',async()=>{signout.disabled=true;try{await request('auth/logout','POST',{})}finally{location.replace('/login/')}});pill.insertAdjacentElement('afterend',signout)}
  document.body.classList.add('ready');byId('auth-state')?.remove();initCatalog();installEditors();initAssistant();initLocalView();
  if(['tasks','storage','documents'].includes(kind()))await refresh();
 }catch(err){if(err.message==='authentication_required'){location.replace('/login/?next='+encodeURIComponent(location.pathname));return}const state=byId('auth-state');if(state){state.innerHTML='';const h=node('h2','','Your Council is temporarily unavailable');const p=node('p','', 'Please retry this connection shortly. Your saved items have not been changed.');const b=node('button','cta','Retry');b.type='button';b.addEventListener('click',()=>location.reload());state.append(h,p,b)}}
})();
