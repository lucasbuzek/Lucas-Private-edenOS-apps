// TENDERS local preparatory compliance matrix. No independent verification,
// qualification pass, legal attestation or submission authorization is implied.
import {makeAuditEvent} from "./workflow.js";
export const COMPLIANCE_STATES=Object.freeze(["OPEN","GAP","EVIDENCE_LINKED","REVIEW_PENDING"]);
const clean=(value,max=1500)=>typeof value==="string"?value.trim().slice(0,max):"";
function requireEntry(record,id){
 const row=(record.complianceMatrix||[]).find(x=>x.id===id);
 if(!row)throw Error("Requirement not in this work item.");
 return row;
}
function updatedRecord(record,rows,action,actor,detail,at){
 if(!clean(actor,120))throw Error("Named actor required.");
 const event=makeAuditEvent(action,clean(actor,120),detail,at);
 const auditTrail=[...(record.auditTrail||[]),event];
 return {...record,complianceMatrix:rows,auditTrail,history:auditTrail,updatedAt:at};
}
export function addComplianceRequirement(record,{requirement,actor="local-user-unverified",at=new Date().toISOString()}={}){
 const label=clean(requirement);
 if(!label)throw Error("Requirement text is mandatory.");
 if(!record||!record.id)throw Error("Tender record required.");
 if((record.complianceMatrix||[]).length>=100)throw Error("Maximum 100 requirements per work item.");
 const row={id:globalThis.crypto?.randomUUID?.()||"req-"+Date.now()+"-"+Math.random().toString(36).slice(2),requirement:label,state:"OPEN",evidenceId:null,createdAt:at,updatedAt:at};
 return updatedRecord(record,[...(record.complianceMatrix||[]),row],"COMPLIANCE_REQUIREMENT_ADDED",actor,{id:row.id,requirement:label},at);
}
export function setComplianceState(record,{id,state,actor="local-user-unverified",at=new Date().toISOString()}={}){
 if(!COMPLIANCE_STATES.includes(state))throw Error("Unrecognized compliance preparation state.");
 const old=requireEntry(record,id);
 if(state==="EVIDENCE_LINKED"&&!old.evidenceId)throw Error("Link an evidence item first.");
 const rows=record.complianceMatrix.map(x=>x.id===id?{...x,state,updatedAt:at}:x);
 return updatedRecord(record,rows,"COMPLIANCE_PREPARATION_STATE",actor,{id,from:old.state,to:state},at);
}
export function linkComplianceEvidence(record,{id,evidenceId,actor="local-user-unverified",at=new Date().toISOString()}={}){
 requireEntry(record,id);
 const ref=clean(evidenceId,200);
 if(ref&&!(record.sourceEvidence||[]).some(e=>e.id===ref))throw Error("Evidence is not recorded for this tender.");
 const rows=record.complianceMatrix.map(x=>x.id===id?{...x,evidenceId:ref||null,state:ref?"EVIDENCE_LINKED":"OPEN",updatedAt:at}:x);
 return updatedRecord(record,rows,"COMPLIANCE_EVIDENCE_REFERENCE",actor,{id,evidenceId:ref||null},at);
}
export function complianceSummary(record){
 const rows=Array.isArray(record.complianceMatrix)?record.complianceMatrix:[];
 return {
  total:rows.length,
  open:rows.filter(x=>x.state==="OPEN").length,
  gaps:rows.filter(x=>x.state==="GAP").length,
  evidenceLinked:rows.filter(x=>x.state==="EVIDENCE_LINKED").length,
  reviewPending:rows.filter(x=>x.state==="REVIEW_PENDING").length,
  independentlyVerified:false,
  readyForSubmission:false
 };
}
