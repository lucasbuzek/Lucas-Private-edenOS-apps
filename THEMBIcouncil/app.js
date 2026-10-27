(()=>{'use strict';
const core=globalThis.THEMBI_CORE; if(!core)throw new Error('Council core missing');
const $=id=>document.getElementById(id);
const STATE={persona:'heartbi',previousPersona:'heartbi',tab:'council',tenant:'personal',privateAuthorized:false,messages:[],tasks:[]};
let privatePending=null;
function e(tag,attrs={},value=''){const n=document.createElement(tag);for(const [k,v] of Object.entries(attrs)){if(k==='class')n.className=v;else if(k==='dataset')for(const [name,val] of Object.entries(v))n.dataset[name]=val;else n.setAttribute(k,v);}if(value!==null&&value!==undefined)n.textContent=String(value);return n;}
function safeDownload(filename,text,mime='text/plain'){const b=new Blob([text],{type:mime}),u=URL.createObjectURL(b),a=document.createElement('a');a.href=u;a.download=filename;a.click();URL.revokeObjectURL(u);}
function navigate(tab){STATE.tab=tab;for(const n of document.querySelectorAll('.panel'))n.classList.toggle('active',n.id==='panel-'+tab);for(const n of document.querySelectorAll('.nav-link'))n.classList.toggle('selected',n.dataset.tab===tab);$('current-tab').textContent={council:'CHORUS',domains:'DOMAINS',about:'ABOUT THE APP',connections:'CONNECTIONS',notes:'PRIVATE NOTES'}[tab]||tab;document.querySelector('.sidebar').classList.remove('open');window.scrollTo?.({top:0,behavior:'smooth'});}
function paintCards(){const grid=$('personas');grid.replaceChildren();for(const p of core.PERSONAS){const b=e('button',{type:'button',class:'persona-card'+(p.private?' private':''),'aria-pressed':String(p.id===STATE.persona)});const art=e('span',{class:'persona-art'},'');const img=e('img',{src:p.image,alt:p.name+' generated character artwork',loading:'lazy'},'');art.append(img);b.append(art,e('strong',{},p.name),e('small',{},p.role));if(p.private)b.append(e('span',{class:'private-label'},'PRIVATE · SELECTABLE'));b.addEventListener('click',()=>selectPersona(p.id));grid.append(b);}}
function poseImage(id,idx){const names=core.POSES[id];if(!names)return core.PERSONAS.find(x=>x.id===id)?.image||'';const name=id==='sexybi'?'SexyBi':'Terry';return `assets/chorus/${name}/${name}_${String(idx+1).padStart(2,'0')}_${names[idx]}.png`;}
function paintDetails(p){$('selected-avatar').src=p.image;$('selected-name').textContent=p.name;$('selected-role').textContent=p.role;$('detail-title').textContent=p.name;$('detail-intro').textContent=p.intro;$('detail-image').src=p.image;$('detail-image').alt=p.name+' generated image';const poses=$('pose-controls');poses.replaceChildren();const names=core.POSES[p.id];if(names){names.forEach((name,i)=>{const b=e('button',{type:'button','aria-pressed':String(false)},name);b.addEventListener('click',()=>{$('detail-image').src=poseImage(p.id,i);for(const x of poses.children)x.setAttribute('aria-pressed',String(x===b));});poses.append(b);});$('source-label').textContent='Seven newly generated pose assets · style/likeness acceptance pending.';}else{$('source-label').textContent='Generated avatar candidate. Original seven-pose set retained inside existing installed plugin.';}}
function selectPersona(id){const p=core.PERSONAS.find(x=>x.id===id);if(!p)return;if(p.private&&!STATE.privateAuthorized){privatePending=id;$('private-modal').hidden=false;return;}
const allowed=core.choice(id,{actor:'thembi',privateOwner:STATE.privateAuthorized,tenant:STATE.tenant});if(!allowed.ok){addMessage('assistant','Private mode cannot be used in a shared/business Council. Return to the private Council.',false);return;}if(id==='terry'&&STATE.persona!=='terry')STATE.previousPersona=STATE.persona;STATE.persona=id;paintCards();paintDetails(p);}
function addMessage(role,text,save=true){const area=$('chat-log');const m=e('div',{class:'message '+role},text);area.append(m);area.scrollTop=area.scrollHeight;if(save)STATE.messages.push({role,text});}
function send(s){const input=String(s||'').trim();if(!input)return;addMessage('user',input);
if(/^terry\s+status\b/i.test(input)){addMessage('assistant','TERRY STATUS · Story-based dialogue: PACKAGED. Offline scripted interactions: AVAILABLE. Live camera, animal telemetry, autonomous pet, animation and live voice integration: NOT CONNECTED OR VERIFIED. Current account/device acceptance: NOT VERIFIED.');return;}
if(/^terry\s+exit\b/i.test(input)){const prior=STATE.persona==='terry'?STATE.previousPersona:STATE.persona;const safe=(prior==='sexybi'&&STATE.privateAuthorized&&STATE.tenant==='personal')?'sexybi':(core.PERSONAS.some(p=>p.id===prior&&!p.private)?prior:'heartbi');selectPersona(safe);addMessage('assistant',`Terry has retired from duty. ${core.PERSONAS.find(p=>p.id===safe).name} is back. No preference was permanently saved.`);return;}
if(/^(?:mydevices|mystorage|myplugins|mcp\s+status|device\s+check|update\s+plugin|storage\s+manager)\b/i.test(input)){addMessage('assistant','This offline preview has no authenticated remote executor. No device, storage, app or plugin was inspected or modified. Use the installed ChatGPT plugin in your own account with separately connected approved provider tools to request a real action.');return;}
const res=core.dispatch(input,{persona:STATE.persona,actor:'thembi',privateOwner:STATE.privateAuthorized,tenant:STATE.tenant});addMessage('assistant',res.text);if(res.kind==='app_description')navigate('about');if(res.kind==='personas')navigate('council');}
function buildDomains(){for(const d of core.DOMAINS){const b=e('article',{class:'card domain-card'},'');b.append(e('div',{class:'eyebrow'},'DOMAIN'),e('h3',{},d.name),e('p',{},d.purpose),e('span',{class:'owner'},d.owner));$('domain-grid').append(b);}}
function buildServices(){for(const s of core.SERVICES){const card=e('article',{class:'card service-card'},'');const typ=(s.state==='WRITER_GRANT_VERIFIED'?'pass':s.state==='NOT_GRANTED'?'fail':'');card.append(e('div',{class:'eyebrow'},'CONNECTED SERVICE'),e('h3',{},s.name),e('p',{},s.description),e('span',{class:'service-status '+typ},s.state.replace(/_/g,' ')));const acts=e('div',{class:'service-actions'},'');if(s.url){const a=e('a',{class:'btn secondary',href:s.url,target:'_blank',rel:'noopener noreferrer'},'Open provider ↗');acts.append(a);}else acts.append(e('span',{class:'muted smallprint'},'No authenticated action available in this offline app'));card.append(acts);$('service-grid').append(card);}}
for(const b of document.querySelectorAll('.nav-link'))b.addEventListener('click',()=>navigate(b.dataset.tab));
for(const b of document.querySelectorAll('[data-action="about"]'))b.addEventListener('click',()=>navigate('about'));
for(const b of document.querySelectorAll('[data-text]'))b.addEventListener('click',()=>send(b.dataset.text));
$('message-form').addEventListener('submit',event=>{event.preventDefault();const i=$('chat-input');send(i.value);i.value='';i.focus()});
$('download-session').addEventListener('click',()=>safeDownload('THEMBIcouncil_private_conversation.json',JSON.stringify({product:'THEMBIcouncil',state:'local scripted transcript',messages:STATE.messages},null,2),'application/json'));
$('export-note').addEventListener('click',()=>safeDownload('THEMBIcouncil_MYjournal.txt',$('note-area').value));
$('clear-note').addEventListener('click',()=>{$('note-area').value='';});
function paintTasks(){const ul=$('task-items');ul.replaceChildren();for(const task of STATE.tasks){const li=e('li',{class:task.done?'completed':''},'');const c=e('input',{type:'checkbox','aria-label':'Completed '+task.text},'');c.checked=task.done;c.addEventListener('change',()=>{task.done=!!c.checked;paintTasks()});const span=e('span',{},task.text);const del=e('button',{class:'delete-task',type:'button','aria-label':'Delete '+task.text},'×');del.addEventListener('click',()=>{STATE.tasks=STATE.tasks.filter(x=>x!==task);paintTasks()});li.append(c,span,del);ul.append(li);}}
$('task-add').addEventListener('click',()=>{const i=$('task-input'),val=i.value.trim().slice(0,180);if(!val)return;STATE.tasks.push({text:val,done:false});i.value='';paintTasks();});
$('export-tasks').addEventListener('click',()=>safeDownload('THEMBIcouncil_tasks.json',JSON.stringify({owner:'Thembi local private preview',tasks:STATE.tasks},null,2),'application/json'));
$('reset-mode').addEventListener('click',()=>{STATE.privateAuthorized=false;STATE.tenant='personal';STATE.previousPersona='heartbi';selectPersona('heartbi')});
$('cancel-private').addEventListener('click',()=>{privatePending=null;$('private-modal').hidden=true});
$('allow-private').addEventListener('click',()=>{STATE.privateAuthorized=true;STATE.tenant='personal';$('private-modal').hidden=true;const pending=privatePending;privatePending=null;selectPersona(pending)});
$('menu').addEventListener('click',()=>$('sidebar').classList.toggle('open'));
// Match the current plugin identity without replacing or deleting historical artwork.
const logo=document.querySelector?.('.identity-art img');if(logo){logo.src='assets/thembi-council-blackgold-logo.png';logo.alt='THEMBIcouncil current black-and-gold logo';}
$('full-description').textContent=core.APP_DESCRIPTION;buildDomains();buildServices();paintCards();paintDetails(core.PERSONAS[0]);
addMessage('assistant','Welcome to THEMBIcouncil. Choose any CHORUS voice—including the private SexyBi mode—or type tellMEaboutME to learn what the app does. Terry is standing by for inspections.');
// Keep conversations and notes only until this browser page closes.

/* Optional local task persistence. Explicit user choice; no journals, chat, auth or private mode saved. */
const TASKS_KEY='THEMBIcouncil_user_saved_tasks_v1';
function taskNotice(message){const n=$('task-storage-status');if(n)n.textContent=message;}
$('save-tasks-local').addEventListener('click',()=>{
 try{localStorage.setItem(TASKS_KEY,JSON.stringify({version:1,savedAt:new Date().toISOString(),tasks:STATE.tasks.map(t=>({text:String(t.text).slice(0,180),done:!!t.done}))}));taskNotice('Saved to this browser only (unencrypted). Private notes and chats were not saved.');}
 catch(e){taskNotice('Saving unavailable in this browser. Use Export task list instead.');}
});
$('restore-tasks-local').addEventListener('click',()=>{
 try{const raw=localStorage.getItem(TASKS_KEY);if(!raw){taskNotice('No saved task list on this browser.');return;}
 const data=JSON.parse(raw);if(data.version!==1||!Array.isArray(data.tasks)||data.tasks.length>500)throw Error('invalid');
 STATE.tasks=data.tasks.filter(t=>t&&typeof t.text==='string').map(t=>({text:t.text.slice(0,180),done:!!t.done}));paintTasks();taskNotice('Restored '+STATE.tasks.length+' local tasks. No remote account accessed.');}
 catch(e){taskNotice('The local file could not be restored. Current list was not changed.');}
});
$('forget-tasks-local').addEventListener('click',()=>{
 try{localStorage.removeItem(TASKS_KEY);taskNotice('Stored task copy removed from this browser. Current in-memory list unchanged.');}
 catch(e){taskNotice('Browser storage is unavailable.');}
});
/* Optional Chrome WebMCP browser-agent adapter, strictly local and permission-scoped.
   Browser WebMCP is not a ChatGPT MCP server, account login or iOS integration. */
try{
 if(document.modelContext&&typeof document.modelContext.registerTool==='function'){
  document.modelContext.registerTool({
   name:'thembicouncil_add_local_task',
   description:'Add a task to the current local THEMBIcouncil task list only. No cloud write or auto-save.',
   inputSchema:{type:'object',properties:{text:{type:'string',maxLength:180}},required:['text'],additionalProperties:false},
   annotations:{readOnlyHint:false,consequentialHint:true},
   execute:async({text})=>{
    const value=String(text||'').trim().slice(0,180);if(!value)return {content:[{type:'text',text:'Task must not be empty.'}]};
    if(STATE.tasks.length>=500)return {content:[{type:'text',text:'Task limit reached.'}]};
    STATE.tasks.push({text:value,done:false});paintTasks();
    return {content:[{type:'text',text:'Task added in this browser only. Use Save tasks to keep it after closing.'}]};
   }
  });
 }
}catch(e){taskNotice('Optional browser-agent support unavailable; ordinary task buttons still work.');}

globalThis.THEMBI_APP_TEST={state:STATE,navigate,selectPersona,send,poseImage,privateModal:()=>!$('private-modal').hidden};
})();
