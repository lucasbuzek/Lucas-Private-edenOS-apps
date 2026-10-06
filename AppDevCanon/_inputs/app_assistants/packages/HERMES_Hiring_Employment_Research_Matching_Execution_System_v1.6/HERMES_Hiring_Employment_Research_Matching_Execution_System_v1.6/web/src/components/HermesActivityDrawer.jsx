import React from "react";
import { X, CircleAlert, CheckCircle2, Clock3, Bot } from "lucide-react";
import HermesSignal from "./HermesSignal";

export default function HermesActivityDrawer({open,onClose,status}){
  if(!open) return null;
  const blockers=status.blockers||[], issues=status.issues||[];
  return <div className="drawerLayer" role="presentation" onMouseDown={e=>{if(e.target===e.currentTarget)onClose();}}>
    <aside className="activityDrawer" role="dialog" aria-modal="true" aria-labelledby="activity-title">
      <div className="drawerHead"><HermesSignal state={status.state} worker={status.worker||"HERMES"}/><button className="iconBtn" onClick={onClose} aria-label="Close HERMES activity"><X size={18}/></button></div>
      <h2 id="activity-title">HERMES Activity</h2><p className="drawerMessage">{status.message}</p>
      <div className="drawerFacts"><div><Bot size={16}/><span>Worker</span><b>{status.worker||"HERMES"}</b></div><div><Clock3 size={16}/><span>Phase</span><b>{status.phase}</b></div><div><CheckCircle2 size={16}/><span>QA</span><b>{status.qa}</b></div></div>
      <section><p className="drawerLabel">CURRENT ACTION</p><b>{status.step}</b></section>
      {blockers.length>0&&<section className="drawerAlert"><CircleAlert size={17}/><div><p className="drawerLabel">BLOCKERS</p>{blockers.map((x,i)=><p key={i}>{x}</p>)}</div></section>}
      {issues.length>0&&<section><p className="drawerLabel">ISSUES</p>{issues.map((x,i)=><p key={i}>{x}</p>)}</section>}
      <section><p className="drawerLabel">NEXT RECOMMENDED</p><b>{status.nextRecommended}</b></section>
      <section><p className="drawerLabel">PIPELINE</p><p>Truth → Discover → Normalize → Match → Prepare → QA → Authorize → Submit → Track → Outcome</p></section>
      <p className="drawerFine">The signal animates only while confirmed work is executing or recovering. Reduced-motion preferences are respected.</p>
    </aside>
  </div>
}
