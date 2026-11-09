'use strict';
const api='/app/api/';
const el=id=>document.getElementById(id);
const state={user:null,tasks:[],notes:[],files:[]};
function setStatus(message,error=false){const e=el('task-feedback');if(e){e.textContent=message;e.style.color=error?'#ae2d61':'#358069';}}
async function request(path,method='GET',body){
  const response=await fetch(api+path,{method,credentials:'same-origin',headers:{'Accept':'application/json',...(body?{'Content-Type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{})});
  const data=await response.json().catch(()=>({error:'invalid_server_response'}));
  if(!response.ok)throw Error(data.error||'HTTP '+response.status);
  return data;
}
function item(tag,className,text){
  const e=document.createElement(tag);if(className)e.className=className;if(text!==undefined)e.textContent=String(text);return e;
}
function byUpdated(a,b){return Number(b.updated_at||0)-Number(a.updated_at||0);}
function renderTasks(){
  const tasks=state.tasks;
  const done=tasks.filter(t=>Boolean(t.done)).length,open=tasks.length-done;
  el('metric-open').textContent=String(open);el('metric-done').textContent=String(done);
  el('metric-notes').textContent=String(state.notes.length);el('metric-files').textContent=String(state.files.length);
  const percent=tasks.length?Math.round(done/tasks.length*100):0;
  el('task-progress').setAttribute('aria-valuenow',String(percent));
  el('task-progress-fill').style.width=percent+'%';
  el('task-progress-percent').textContent=tasks.length?percent+'% complete':'No tasks yet';
  el('task-progress-label').textContent=tasks.length?done+' of '+tasks.length+' finished':'Add a task to get started';
  const list=el('task-list');list.replaceChildren();
  const active=tasks.filter(t=>!t.done).sort(byUpdated).slice(0,7);
  if(!active.length){list.append(item('li','muted',tasks.length?'Your current tasks are complete.':'No tasks saved yet. Add your first task above.'));return;}
  for(const task of active){
    const li=item('li');const label=item('label');const tick=item('input');tick.type='checkbox';tick.setAttribute('aria-label','Complete '+task.title);
    const title=item('span','',task.title);label.append(tick,title);li.append(label);list.append(li);
    tick.addEventListener('change',async()=>{
      tick.disabled=true;
      try{await request('items','PATCH',{id:task.id,version:task.version,done:true});setStatus('Task completed.');await reload();}
      catch(e){tick.checked=false;tick.disabled=false;setStatus('Could not update the task: '+e.message,true);}
    });
  }
}
function renderRecent(){
  const list=el('recent-list');list.replaceChildren();
  const entries=[...state.tasks,...state.notes,...state.files].sort(byUpdated).slice(0,6);
  if(!entries.length){list.append(item('li','muted','Your recent work will appear here once you save something.'));return;}
  for(const entry of entries){
    const li=item('li');const a=item('a');a.href=entry.kind==='task'?'/app/tasks/':entry.kind==='file'?'/app/storage/':'/app/documents/';
    const tag=item('span','file-tag',entry.kind==='file'?'FILE':entry.kind.toUpperCase());a.append(tag,item('span','',entry.title));
    const time=item('time','',new Date(entry.updated_at||entry.created_at||Date.now()).toLocaleDateString(undefined,{month:'short',day:'numeric'}));
    li.append(a,time);list.append(li);
  }
}
async function reload(){
  const [tasks,notes,files]=await Promise.all([request('items?kind=task'),request('items?kind=note'),request('items?kind=file')]);
  state.tasks=tasks.items||[];state.notes=notes.items||[];state.files=files.items||[];
  renderTasks();renderRecent();
  el('connection-state').textContent='Personal Council records loaded';
}
function initTaskForm(){
  el('quick-task').addEventListener('submit',async ev=>{
    ev.preventDefault();const input=el('new-task');const title=input.value.trim();if(!title)return;
    const button=el('create-task');button.disabled=true;setStatus('Saving…');
    try{await request('items','POST',{kind:'task',title,body:''});input.value='';await reload();setStatus('Saved to your private tasks.');input.focus();}
    catch(e){setStatus('Could not save: '+e.message,true);}
    finally{button.disabled=false;}
  });
}
function fail(message){
  const gate=el('auth-state');gate.replaceChildren();
  const inside=item('div','gate-inner');inside.append(item('h1','','Your Council is temporarily unavailable'),item('p','',message));
  const retry=item('button','','Retry connection');retry.type='button';retry.addEventListener('click',()=>location.reload());inside.append(retry);gate.append(inside);
}
async function start(){
  try{
    const user=await request('me');
    if(!user.authenticated)throw Error('authentication_required');
    state.user=user;
    const name=(user.display_name|| (user.role==='owner_admin'?'Thembi':'Lucas')).trim().split(/\s+/)[0];
    el('welcome-name').textContent=name;
    el('avatar-initial').textContent=name.slice(0,1).toUpperCase();
    el('account-role').textContent=user.role==='owner_admin'?'Owner':'Setup administrator';
    el('today-date').textContent=new Date().toLocaleDateString(undefined,{weekday:'short',month:'long',day:'numeric',year:'numeric'});
    el('logout').addEventListener('click',async()=>{el('logout').disabled=true;try{await request('auth/logout','POST',{});}finally{location.assign('/login/');}});
    initTaskForm();
    el('workspace').hidden=false;el('auth-state').hidden=true;
    try{await reload();}catch(e){el('connection-state').textContent='Records unavailable';setStatus('Could not load your private items: '+e.message,true);}
  }catch(e){
    if(e.message==='authentication_required'){location.replace('/login/?next='+encodeURIComponent(location.pathname));return;}
    fail('Your session could not be verified. No personal data has been displayed.');
  }
}
start();
