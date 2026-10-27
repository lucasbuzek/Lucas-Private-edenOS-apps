/** THEMBIcouncil functional offline core — no accounts, impersonation or network dispatch. */
(function(root,factory){const v=factory(); if(typeof module==='object'&&module.exports)module.exports=v; if(root)root.THEMBI_CORE=v;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const PERSONAS=Object.freeze([
{id:'heartbi',name:'Heartbi',role:'Family First',domain:'Family, Home & Terry',color:'#f7bacd',image:'assets/avatars/Heartbi.png',intro:'Family plans, relationships and making daily life more manageable.'},
{id:'fitbi',name:'Fitbi',role:'Fitness',domain:'Fitness, Dance & Creative',color:'#cdb3fd',image:'assets/avatars/Fitbi.png',intro:'Movement, dancing and manageable fitness goals.'},
{id:'dreambi',name:'Dreambi',role:'Sleepyhead',domain:'Personal & Wellbeing',color:'#d0c0ff',image:'assets/avatars/Dreambi.png',intro:'Quiet moments, rest and gentle routines.'},
{id:'bossbi',name:'Bossbi',role:'Work Pays the Bills',domain:'Work, Employers & Career',color:'#ccb7d9',image:'assets/avatars/Bossbi.png',intro:'Job applications, company work, priorities and tenders.'},
{id:'roambi',name:'Roambi',role:'Traveller / Explorer',domain:'Travel, Books, Anime & Learning',color:'#8be1e2',image:'assets/avatars/Roambi.png',intro:'Trip ideas, new places and experiences.'},
{id:'storybi',name:'Storybi',role:'Books & Anime Nerd',domain:'Travel, Books, Anime & Learning',color:'#f4b1d9',image:'assets/avatars/Storybi.png',intro:'Books, anime, manga and spoiler-aware discovery.'},
{id:'sexybi',name:'SexyBi',role:'Private • Couple mode',domain:'Personal & Wellbeing',color:'#f6a4ba',image:'assets/avatars/SexyBi.png',private:true,intro:'Personal confidence, private style and playful conversations — only in Thembi’s authorized private Council.'},
{id:'terry',name:'Terry',role:'Chief Inspector · ChatGPT Pet',domain:'Family, Home & Terry',color:'#e1bc9b',image:'assets/avatars/Terry.png',intro:'Novel-derived fictional inspections, humour and feline management.'}
]);
const DOMAINS=Object.freeze([
{name:'Personal & Wellbeing',purpose:'Routines, self-reported mood and private notes.',owner:'Thembi private'},
{name:'Family, Home & Terry',purpose:'Home routines, family planning and Terry pet conversations.',owner:'Private or separately approved family'},
{name:'Work, Employers & Career',purpose:'Job alerts, employment correspondence, documents and applications.',owner:'Thembi private'},
{name:'Businesses, Tenders & Procurement',purpose:'Company logistics, bids and tender administration.',owner:'Slindokuhle Transport / authorized business'},
{name:'Money, Finance & Property',purpose:'Personal financial planning and property; separate from company accounts.',owner:'Thembi private'},
{name:'Fitness, Dance & Creative',purpose:'Dance, movement, exercise and MEMOJIME art.',owner:'Thembi private'},
{name:'Travel, Books, Anime & Learning',purpose:'Travel discoveries, reading lists, anime and courses.',owner:'Thembi private'},
{name:'Digital Life, Connections & Portals',purpose:'Gmail, Drive, ELYSIUM, HEIMDALL, BIFROST and approved cloud destinations.',owner:'Individually authenticated'}
]);
const SERVICES=Object.freeze([
{name:'Gmail',key:'gmail',state:'OWNER_CONNECTED_IN_CHATGPT_NOT_WEB_APP',description:'Thembi Gmail was verified in ChatGPT. This offline UI cannot read or change messages.',url:'https://mail.google.com/mail/u/0/#inbox'},
{name:'Google Drive — Transport',key:'transport',state:'WRITER_GRANT_VERIFIED',description:'Thembi has verified writer access to the Slindokuhle Transport tenders folder.',url:'https://drive.google.com/drive/folders/14BgnodZ4VXWsK5Me_Lf1cPHHpX54w6eL'},
{name:'Google Drive — Council Shared',key:'familydrive',state:'NOT_GRANTED',description:'The Council family/business folder failed under Thembi’s Google account. Grant required.',url:'https://drive.google.com/drive/folders/1ktUwxMzQ3x30Rl7lqQmmWT4f8j9u75el'},
{name:'ELYSIUM',key:'elysium',state:'PLUGIN_REGISTERED_RUNTIME_UNKNOWN',description:'Personal and Business portals must be separately authenticated.',url:null},
{name:'HEIMDALL',key:'heimdall',state:'RUNTIME_UNKNOWN',description:'View and organize only authorized workspace content.',url:null},
{name:'BIFROST',key:'bifrost',state:'PLUGIN_REGISTERED_RUNTIME_UNKNOWN',description:'Connections, identity and storage routing require real authenticated capabilities.',url:null},
{name:'MEMOJIME',key:'memojime',state:'PLUGIN_REGISTERED',description:'Existing avatar-generation specialist; real owner-approved image pipeline needs host tools.',url:null},
{name:'SlindokuhleCouncil',key:'slindocouncil',state:'SHARING_PENDING',description:'Separate family/business Council tenant; no inherited Lucas records.',url:null}
]);
const POSES={
sexybi:['Hello','LookBack','Playful','Heart','Stretch','Cozy','Sleep'],
terry:['Alert','Paw','Patrol','Inspect','Verdict','Nap','Stretch']
};
const APP_DESCRIPTION=`THEMBIcouncil — One Core. Your Voices. Your Choices.\n\nTHEMBIcouncil is Thembi’s private AI Council and personal coordination environment, designed as a single adaptable assistant rather than eight separate accounts. Its CHORUS personalities let Thembi choose a voice for family and home (Heartbi), fitness and dance (Fitbi), rest (Dreambi), work and business (Bossbi), travel (Roambi), books and anime (Storybi), couple-private style and conversation (SexyBi), or the novel-based fictional pet adviser Terry.\n\nIt covers eight domains: personal wellbeing; family, home and Terry; work and career; businesses and tenders; finance and property; fitness and creativity; travel, reading and learning; and digital connections. Thembi can select and change modes without surrendering control of her data.\n\nSpecialist routes include MEMOJIME for selected avatar artwork; Slindokuhle Transport tenders; and potential ELYSIUM, HEIMDALL and BIFROST services. A route name does NOT create a connection. Every account, family/business tenant, device and third-party action requires its own authenticated permission.\n\nThis offline working build implements real local persona selection, Terry’s scripted conversation, source-based artwork display, private-mode gating, notes, task checklists and transcript export. It has no API credentials, background connections, live Gmail access, AI model inference or native device automation. Its outputs are deterministic local interactions, not a substitute for the separately verified ChatGPT experience.\n\nUse: choose CHORUS, select any voice, type your question or choose an action. Try “Terry joke — Dad lost his keys”, “Terry inspect the garden gate”, “tellMEaboutME”, “MYmood”, or “toTENDERS”. Select Connections to see which services have real grants versus pending authorization. SexyBi is directly selectable from the private Council; selecting it confirms personal scope without exporting anything.`;
function clean(s){return String(s??'').trim().slice(0,2500);}
function visiblePersonas(ctx={}){return PERSONAS.filter(p=>!p.private||ctx.privateOwner===true||ctx.includePrivateOption===true);}
function choice(id,ctx={}){
 const p=PERSONAS.find(x=>x.id===id);if(!p)return {ok:false,reason:'UNKNOWN_PERSONA'};
 if(p.private && ctx.actor!=='thembi' && ctx.privateOwner!==true) return {ok:false,reason:'PRIVATE_OWNER_REQUIRED'};
 if(p.private && ctx.tenant && ['family','business','public','slindokuhle','buzek','transport'].includes(ctx.tenant.toLowerCase()))return {ok:false,reason:'PRIVATE_TENANT_DENIED'};
 return {ok:true,persona:p};
}
function terryJoke(t){const topic=clean(t)||'Dad lost his keys';return `CHIEF INSPECTOR TERRY · COUNCIL MEETING\nCase: ${topic}\n\nMinimalist: We should have fewer hiding places.\nEngineer: A claim is not evidence. Where was it last seen?\nAccountant: This meeting has exceeded our allotted nap budget.\nMr. Chicken (uninvited): Perhaps try the obvious.\n\nTerry’s Verdict: Dad will conduct the search. I shall supervise from the sunbeam. Mr. Chicken will receive absolutely no credit. Case recorded, pending a biscuit.`;}
function terryInspect(t){const topic=clean(t)||'the garden';return `TERRY’S INSPECTION · ${topic}\n\nObservation: I have no live camera or sensor feed.\nPossible explanation: Routine conditions, a genuine problem, or the five woolly suspects reorganizing vegetables.\nVerdict: Evidence insufficient. Suspicion carefully filed.\nNext step: Inspect ${topic} in person, document what you observe, and check for hazards before action.\n\nChief Inspector Terry, retiring to an appropriate chair.`;}
function terryReply(t){let s=clean(t);if(/^terry\s+(?:joke|council)\b/i.test(s))return terryJoke(s.replace(/^terry\s+(?:joke|council)\s*[-—:]?\s*/i,''));if(/^terry\s+inspect\b/i.test(s))return terryInspect(s.replace(/^terry\s+inspect\s*/i,''));if(/^terry\s+(?:goodnight|nap|sleep)\b/i.test(s))return 'The evening shift is complete. Dad and Human Mum may retire. Mr. Chicken has been instructed to stop organizing committees. I shall sleep with one eye on the biscuit cupboard. *purr*';if(/sheep|cabbage/i.test(s))return 'Five woolly suspects. A cabbage has gone missing. I am not accusing anyone until the evidence is in. That said, Mr. Chicken is making a list.';if(/keys/i.test(s))return terryJoke('Dad lost his keys');return 'Chief Inspector Terry reporting. I have checked the window and identified three suspicious sunbeams. Please present your observations; I distinguish evidence from dramatic speculation.';}
function summaryPrompt(name,msg){const v=clean(msg);const topic=v||'your next step';const variants={
heartbi:`HEARTBI · Family First\nFor “${topic}”: choose what matters most today, share household duties fairly and keep time for each other. Which part needs a simple plan?`,
fitbi:`FITBI · Fitness\nFor “${topic}”: start with comfortable movement, add a manageable practice block, and finish with a cooldown. I do not have live Health or motion data in this offline build.`,
dreambi:`DREAMBI · Sleepyhead\nFor “${topic}”: simplify the next hour, reduce interruptions, and choose one gentle action. You do not need to complete everything tonight.`,
bossbi:`BOSSBI · Work Pays the Bills\nTask: ${topic}\n1. Define the deliverable and deadline.\n2. Identify owner and existing source documents.\n3. Separate employer, business and family permissions.\n4. Record next action.\nNo tender or mailbox was accessed.`,
roambi:`ROAMBI · Traveller / Explorer\nTravel idea: ${topic}\nCompare route, budget, entry requirements and interests. Live prices, weather and bookings are not connected to this offline build.`,
storybi:`STORYBI · Books & Anime\nFor “${topic}”: I can organize a spoiler-aware reading/watchlist or draft discussion prompts. Say “no spoilers” and I will avoid plot revelations.`,
sexybi:`SEXYBI · Private CHORUS\nFor “${topic}”: choose the mood you want—confident, playful or relaxed. We can explore style ideas and private creative writing. Nothing is shared outside this private conversation.`
};return variants[name]??'Select a CHORUS voice.';}
function dispatch(input,ctx={}){
 const s=clean(input);if(!s)return {kind:'empty',text:''};
 if(/^(?:tellmeaboutme|tell\s+me\s+about\s+me|about\s+the\s+app)\b/i.test(s))return {kind:'app_description',text:APP_DESCRIPTION};
 if(/^(?:chorus|personas|show\s+(?:my\s+)?voices)\b/i.test(s))return {kind:'personas',text:`CHORUS — eight members: ${PERSONAS.map(p=>p.name+(p.private?' (private)':'')).join(', ')}. Choose a voice; SexyBi is directly selectable in Thembi’s private Council.`};
 if(/^terry\b|^ask\s+terry\b/i.test(s))return {kind:'terry',text:terryReply(s)};
 if(/^(?:myjournal|journal)\b/i.test(s))return {kind:'journal',text:'MYjournal is private. Write a note in Notes and explicitly export it if you choose. This offline build does not upload or automatically save private journal content.'};
 if(/^(?:mymood|mood)\b/i.test(s))return {kind:'mood',text:'MYmood: How do you describe your mood right now? You choose the words; I will not diagnose feelings from your appearance.'};
 if(/^(?:toBEDE|BEDE\s+tellMEaboutME)\b/i.test(s))return {kind:'specialist_description',text:'BEDE — Bibliography, Evidence, Documentation & Enactment. BEDE offers source-grounded historical research and historical reenactment. This offline Council can describe BEDE; it has no installed BEDE executor or account permission. Invoke the separately installed BEDE specialist in your own ChatGPT account for real research, and verify original sources before use.'};
 if(/^to(?:bifrost|heimdall|elysium|tenders|memojime|slindokuhle|storage|gmail|googledrive)\b/i.test(s))return {kind:'connection',text:'This route is recognized, but the offline application has no authenticated external executor. Use Connections for actual permissions and provider links. No data was sent.'};
 if(/^corecouncilsetup\b/i.test(s))return {kind:'setup',text:'Choose any of the eight CHORUS modes, select your preferred theme, and enable connections in your own authenticated accounts. No forced first-run questionnaire.'};
 const selected=choice(ctx.persona||'heartbi',ctx);if(!selected.ok)return {kind:'denied',text:'Private persona is not available for the current actor/tenant. Switch to Thembi’s authorized private Council.'};
 if(selected.persona.id==='terry')return {kind:'terry',text:terryReply(s)};
 return {kind:'persona',text:summaryPrompt(selected.persona.id,s)};
}
return Object.freeze({PERSONAS,DOMAINS,SERVICES,POSES,APP_DESCRIPTION,visiblePersonas,choice,dispatch,terryJoke,terryInspect,terryReply});
});
