import React, { useEffect, useMemo, useState } from "react";
import { BriefcaseBusiness, Building2, FileText, Home, LogOut, Search, Settings, UserRound, Activity, ExternalLink, Copy, ShieldCheck, ChevronDown, ChevronUp, Gauge, CircleAlert } from "lucide-react";
import { configured, supabase } from "./lib/supabase";
import HermesSignal from "./components/HermesSignal";
import HermesActivityDrawer from "./components/HermesActivityDrawer";

const NAV = [
  ["Home", Home], ["Opportunities", Search], ["Workspace", BriefcaseBusiness],
  ["Documents", FileText], ["Profile", UserRound], ["Activity", Activity], ["Settings", Settings]
];
const UI_MODES=["AUTO","TINY","COMPACT","FULL"];
const demo = [
  {id:"1", kind:"JOB", title:"Example role", org:"Example Employer", meta:"Remote · New", why:"Matches selected role family and verified skills", status:"DISCOVERED", url:"https://example.com"},
  {id:"2", kind:"TENDER", title:"Example services tender", org:"Example Buyer", meta:"Closes in 12 days", why:"Capability match; 2 requirements need verification", status:"REVIEWING", url:"https://example.com"}
];

function Login() {
  const signIn = async provider => {
    if (!configured) return alert("Configure Supabase environment variables first.");
    await supabase.auth.signInWithOAuth({ provider, options:{ redirectTo: window.location.origin }});
  };
  return <main className="login"><section className="loginCard">
    <div className="mark">H</div><p className="eyebrow">HIRING · EMPLOYMENT · RESEARCH · MATCHING · EXECUTION</p>
    <h1>HERMES</h1><p className="lede">One workspace for opportunities, applications, tenders and bid preparation.</p>
    <button className="primary" onClick={()=>signIn("google")}>Continue with Google</button>
    <button onClick={()=>signIn("apple")}>Continue with Apple</button>
    {!configured && <p className="warning">Setup mode: add Supabase variables to enable secure login.</p>}
    <p className="fine">Your private profile and company data are separated by authenticated user access.</p>
  </section></main>
}

export default function App(){
  const [session,setSession]=useState(null), [loading,setLoading]=useState(configured), [page,setPage]=useState("Home");
  const [mode,setMode]=useState(localStorage.getItem("hermes-mode") || "PERSON");
  const [uiMode,setUiMode]=useState(localStorage.getItem("hermes-ui-mode") || "AUTO");
  const [opps,setOpps]=useState(demo);
  const [activityOpen,setActivityOpen]=useState(false);

  useEffect(()=>{ if(!configured){setLoading(false);return;} supabase.auth.getSession().then(({data})=>{setSession(data.session);setLoading(false)}); const {data:{subscription}}=supabase.auth.onAuthStateChange((_e,s)=>setSession(s)); return ()=>subscription.unsubscribe(); },[]);
  useEffect(()=>localStorage.setItem("hermes-mode",mode),[mode]);
  useEffect(()=>localStorage.setItem("hermes-ui-mode",uiMode),[uiMode]);
  useEffect(()=>{ if(!session || !configured) return; supabase.from("opportunities").select("*").order("created_at",{ascending:false}).limit(50).then(({data,error})=>{ if(!error && data?.length) setOpps(data.map(x=>({id:x.id,kind:x.kind,title:x.title,org:x.organization,meta:x.location||x.deadline||"Saved opportunity",why:x.match_summary||"Awaiting analysis",status:x.status,url:x.canonical_url}))) }); },[session]);

  const visible=useMemo(()=>opps.filter(o=>mode==="HYBRID"||(mode==="PERSON"?o.kind!=="TENDER":o.kind!=="JOB")),[opps,mode]);
  const status=useMemo(()=>({system:"HERMES",module:page,project:mode,phase:configured?"SETUP":"LOCAL PREVIEW",step:configured?"Review profile and connect sources":"Configure secure backend",state:"WAITING",worker:"HERMES",stageProgress:null,overallProgress:null,message:configured?"No autonomous operation is currently running.":"Starter UI is running; secure backend is not configured.",completedCount:0,totalCount:0,issues:configured?[]:["Supabase environment variables are not configured in this preview."],blockers:configured?[]:["Complete profile/source setup before discovery can run."],artifacts:[],qa:"NOT RUN",nextRecommended:configured?"Open Profile and verify authoritative truth data":"Follow Installation to configure Supabase authentication and database",nextOptional:["Review Opportunities UI","Inspect FULL status"],requiresInput:configured?[]:["Supabase project credentials"],canAutoContinue:false}),[page,mode]);

  if(loading) return <main className="center">Loading HERMES…</main>;
  if(!session && configured) return <Login/>;
  return <div className="app">
    <aside><div className="brand"><HermesSignal state={status.state} worker={status.worker} size={36} label={false} onClick={()=>setActivityOpen(true)}/><div><b>HERMES</b><span>Opportunity system</span></div></div><nav>{NAV.map(([n,I])=><button key={n} className={page===n?"active":""} onClick={()=>setPage(n)}><I size={18}/>{n}</button>)}</nav><div className="asideFoot">{session&&<button onClick={()=>supabase.auth.signOut()}><LogOut size={18}/>Sign out</button>}</div></aside>
    <main>
      <header><div><p className="eyebrow">HERMES / {mode}</p><h1>{page}</h1></div><div className="modes">{["PERSON","COMPANY","HYBRID"].map(m=><button key={m} className={mode===m?"selected":""} onClick={()=>setMode(m)}>{m}</button>)}</div></header>
      <HermesStatus status={status} uiMode={uiMode} setUiMode={setUiMode} onSignal={()=>setActivityOpen(true)}/>
      {page==="Home"&&<section><div className="hero"><div><p className="eyebrow">ATTENTION</p><h2>What needs you now</h2><p>Deadlines, missing facts and prepared work appear here. HERMES keeps automation explainable.</p></div><ShieldCheck size={36}/></div><div className="stats"><article><b>{visible.length}</b><span>Visible opportunities</span></article><article><b>0</b><span>Ready to submit</span></article><article><b>{status.blockers.length}</b><span>Blocking gaps</span></article></div><h2 className="sectionTitle">Recent opportunities</h2><Cards items={visible.slice(0,4)}/></section>}
      {page==="Opportunities"&&<section><div className="toolbar"><input placeholder="Search roles, tenders, companies, skills…"/><button className="primary" disabled title="Connect discovery sources first">Run search</button></div><Cards items={visible}/></section>}
      {page==="Workspace"&&<Empty title="Application & bid workspace" text="Selected opportunities move through preparation, ready, submitted and outcome stages here."/>}
      {page==="Documents"&&<Empty title="Document library" text="Master records, industry variants, application snapshots, bid packages and the Compliance Vault live here."/>}
      {page==="Profile"&&<Empty title={mode==="COMPANY"?"Company Truth":mode==="PERSON"?"Candidate Truth":"Candidate + Company Truth"} text="Upload source documents, review extracted facts, and approve the authoritative information HERMES may use."/>}
      {page==="Activity"&&<Empty title="Activity & audit" text="Search runs, document generations, state changes, agent actions, errors and user approvals appear here."/>}
      {page==="Settings"&&<section className="empty"><h2>Settings</h2><p>Configure search sources, AI providers, agent level, notifications, privacy, exports and advanced options.</p><h3>UIbasic</h3><div className="uiChoices">{UI_MODES.map(m=><button key={m} className={uiMode===m?"selected":""} onClick={()=>setUiMode(m)}>UI {m}</button>)}</div></section>}
    </main>
    <button className="mobileSignal" onClick={()=>setActivityOpen(true)} aria-label="Open HERMES activity"><HermesSignal state={status.state} worker={status.worker} size={28} label={false}/></button>
    <HermesActivityDrawer open={activityOpen} onClose={()=>setActivityOpen(false)} status={status}/>
    <div className="mobileNav">{NAV.slice(0,5).map(([n,I])=><button key={n} className={page===n?"active":""} onClick={()=>setPage(n)}><I size={20}/><span>{n}</span></button>)}</div>
  </div>
}

function HermesStatus({status,uiMode,setUiMode,onSignal}){
  const [expanded,setExpanded]=useState(false);
  const effective=uiMode==="AUTO"?(status.state==="ACTIVE"?"TINY":["BLOCKED","FAILED","QA","COMPLETE"].includes(status.state)?"FULL":"COMPACT"):uiMode;
  const full=effective==="FULL"||expanded;
  return <section className={`statusPanel ${effective.toLowerCase()}`} aria-label="HERMES status">
    <div className="statusLine"><div className="statusIdentity"><HermesSignal state={status.state} worker={status.worker} size={24} label={false} onClick={onSignal}/><b>{status.system}</b><span>{status.module} · {status.step}</span><span className={`state state-${status.state.toLowerCase()}`}>{status.state}</span></div><div className="statusTools"><select value={uiMode} onChange={e=>setUiMode(e.target.value)} aria-label="UIbasic mode">{UI_MODES.map(m=><option key={m}>{m}</option>)}</select><button className="iconBtn" onClick={()=>setExpanded(v=>!v)} aria-label={full?"Collapse status":"Expand status"}>{full?<ChevronUp size={17}/>:<ChevronDown size={17}/>}</button></div></div>
    {effective!=="TINY"&&<div className="statusCompact"><p>{status.message}</p><div className="next"><b>Next</b><span>{status.nextRecommended}</span></div>{status.blockers.length>0&&<div className="blocker"><CircleAlert size={16}/><span>{status.blockers[0]}</span></div>}</div>}
    {full&&<div className="statusFull"><div className="statusGrid"><div><span>PHASE</span><b>{status.phase}</b></div><div><span>STAGE PROGRESS</span><b>{status.stageProgress??"INDETERMINATE"}</b></div><div><span>OVERALL</span><b>{status.overallProgress??"INDETERMINATE"}</b></div><div><span>QA</span><b>{status.qa}</b></div></div><div className="pipeline"><b>Pipeline</b><span>Truth → Discover → Normalize → Match → Prepare → QA → Authorize → Submit → Track → Outcome</span></div><div className="decisionGrid"><div><b>RECOMMENDED</b><p>{status.nextRecommended}</p></div><div><b>OPTIONAL</b><p>{status.nextOptional.join(" · ")||"None"}</p></div><div><b>REQUIRES INPUT</b><p>{status.requiresInput.join(" · ")||"None"}</p></div><div><b>AUTO-CONTINUE</b><p>{status.canAutoContinue?"Available":"Unavailable at current state"}</p></div></div></div>}
  </section>
}
function Cards({items}){ const copy=u=>navigator.clipboard?.writeText(u); return <div className="cards">{items.map(o=><article className="card" key={o.id}><div className="cardTop"><span className="pill">{o.kind}</span><span className="status">{o.status}</span></div><h3>{o.title}</h3><p className="org">{o.org}</p><p className="meta">{o.meta}</p><div className="why"><b>Why surfaced</b><span>{o.why}</span></div><div className="actions"><a className="primary linkButton" href={o.url||"#"} target="_blank" rel="noopener noreferrer"><ExternalLink size={16}/>Open</a><button onClick={()=>copy(o.url)} aria-label="Copy link"><Copy size={16}/></button></div></article>)}</div> }
function Empty({title,text}){return <section className="empty"><h2>{title}</h2><p>{text}</p><button className="primary" disabled title="This starter requires the next implementation phase">Continue setup</button></section>}
