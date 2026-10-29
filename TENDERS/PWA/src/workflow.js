import {PRIVATE_CONTEXT_ID, WORK_MODES, normalizeContexts, recordContextId} from "./workModes.js";
export const SCHEMA_VERSION = 3;
export const STATUSES = ["DISCOVERED","VERIFIED","QUALIFIED","IN_PREPARATION","VALIDATED","APPROVED_TO_SUBMIT","SUBMITTED","AWAITING_DECISION","AWARDED","UNSUCCESSFUL","CONTRACT_ACTIVE","DELIVERY_COMPLETE","CLOSED","BLOCKED","UNKNOWN","CANCELLED","EXPIRED","WITHDRAWN","ON_HOLD"];
export const EVIDENCE_TYPES = ["official_notice","source_page","amendment","eligibility_document","compliance_document","qualification_review","bid_review","approval_record","submission_receipt","portal_confirmation","clarification","award_notice","contract","delivery_acceptance","invoice","payment_confirmation","closeout_record","other"];
const TRANSITIONS = {
 DISCOVERED:["VERIFIED","BLOCKED","UNKNOWN","CANCELLED","EXPIRED","WITHDRAWN","ON_HOLD"],
 VERIFIED:["QUALIFIED","BLOCKED","UNKNOWN","CANCELLED","EXPIRED","WITHDRAWN","ON_HOLD"],
 QUALIFIED:["IN_PREPARATION","BLOCKED","WITHDRAWN","ON_HOLD"],
 IN_PREPARATION:["VALIDATED","BLOCKED","WITHDRAWN","ON_HOLD"],
 VALIDATED:["IN_PREPARATION","APPROVED_TO_SUBMIT","BLOCKED","ON_HOLD"],
 APPROVED_TO_SUBMIT:["IN_PREPARATION","SUBMITTED","ON_HOLD"],
 SUBMITTED:["AWAITING_DECISION","AWARDED","UNSUCCESSFUL","CANCELLED","ON_HOLD"],
 AWAITING_DECISION:["AWARDED","UNSUCCESSFUL","CANCELLED","ON_HOLD"],
 AWARDED:["CONTRACT_ACTIVE","ON_HOLD"],
 CONTRACT_ACTIVE:["DELIVERY_COMPLETE","ON_HOLD"],
 DELIVERY_COMPLETE:["CLOSED","CONTRACT_ACTIVE"],
 BLOCKED:["DISCOVERED","VERIFIED","QUALIFIED","IN_PREPARATION","WITHDRAWN","CANCELLED"],
 UNKNOWN:["DISCOVERED","VERIFIED","CANCELLED","WITHDRAWN"],
 ON_HOLD:["DISCOVERED","VERIFIED","QUALIFIED","IN_PREPARATION","VALIDATED","APPROVED_TO_SUBMIT","SUBMITTED","AWAITING_DECISION","AWARDED","UNSUCCESSFUL","CONTRACT_ACTIVE","DELIVERY_COMPLETE","CLOSED","WITHDRAWN","CANCELLED"],
};
const EVIDENCE_REQUIRED = {
 VERIFIED:{types:["official_notice","source_page"],verified:true},
 QUALIFIED:{types:["qualification_review"],verified:true},
 VALIDATED:{types:["bid_review"],verified:true},
 SUBMITTED:{types:["submission_receipt","portal_confirmation"]},
 AWARDED:{types:["award_notice"]},
 UNSUCCESSFUL:{types:["award_notice"]},
 CONTRACT_ACTIVE:{types:["contract"]},
 DELIVERY_COMPLETE:{types:["delivery_acceptance"]},
 CLOSED:{types:["closeout_record"]},
};
export function makeAuditEvent(action, actor, detail={}, at=new Date().toISOString()) {
 const who=String(actor??"").trim();
 if(!who)throw new Error("A named actor is required for an auditable event.");
 return {id:globalThis.crypto?.randomUUID?.() ?? `audit-${Date.now()}-${Math.random().toString(16).slice(2)}`,action,actor:who,at,detail};
}
export function migrateWorkspace(value) {
 const input = value && typeof value === "object" ? value : {};
 const from = Number(input.schemaVersion || 1);
 if (from > SCHEMA_VERSION) throw new Error(`Backup schema ${from} is newer than supported schema ${SCHEMA_VERSION}.`);
 const records = Array.isArray(input.records) ? input.records.map(old => {
  const record = {...old};
  record.sourceEvidence = Array.isArray(old.sourceEvidence) ? old.sourceEvidence : (Array.isArray(old.evidence) ? old.evidence.map(e => ({...e,recordedAt:e.recordedAt||e.at||old.createdAt||new Date(0).toISOString(),legacy:true})) : []);
  record.approvals = Array.isArray(old.approvals) ? old.approvals : [];
  record.auditTrail = Array.isArray(old.auditTrail) ? old.auditTrail : (Array.isArray(old.history) ? old.history.map(h => ({...h,action:"LEGACY_STATUS_EVENT",actor:"migration",detail:{note:h.note||"Migrated from schema v1"}})) : []);
  record.history = record.auditTrail;
  record.lastVerifiedAt = old.lastVerifiedAt || null;
  record.schemaVersion = SCHEMA_VERSION;
  record.contextId = recordContextId(record);
  record.serviceMode = WORK_MODES[record.serviceMode] ? record.serviceMode : "supplier";
  return record;
 }) : [];
 const contexts=normalizeContexts(input.contexts);
 const activeContextId=contexts.some(c=>c.id===input.activeContextId)?input.activeContextId:PRIVATE_CONTEXT_ID;
 const blankProfile={organisation:"",sectors:"",geography:"",registrations:""};
 const profilesByContext=input.profilesByContext&&typeof input.profilesByContext==="object"&&!Array.isArray(input.profilesByContext)?Object.fromEntries(Object.entries(input.profilesByContext).filter(([id,value])=>contexts.some(c=>c.id===id)&&value&&typeof value==="object"&&!Array.isArray(value))):{[PRIVATE_CONTEXT_ID]:input.profile||blankProfile};
 const privateProfile=profilesByContext[PRIVATE_CONTEXT_ID]||blankProfile;
 return {schemaVersion:SCHEMA_VERSION,migratedFrom:from,records,contexts,activeContextId,profile:privateProfile,profilesByContext,migratedAt:from<SCHEMA_VERSION?new Date().toISOString():input.migratedAt||null};
}
export function validateEvidence(evidence) {
 const errors=[];
 if(!evidence || !EVIDENCE_TYPES.includes(evidence.type)) errors.push("Choose a supported evidence type.");
 if(!evidence?.title?.trim()) errors.push("Evidence title is required.");
 if(!evidence?.sourceUrl?.trim() && !evidence?.reference?.trim()) errors.push("Provide a source URL or an identifiable document/reference.");
 if(evidence?.sourceUrl){try{const u=new URL(evidence.sourceUrl);if(!["http:","https:"].includes(u.protocol))errors.push("Evidence URLs must use HTTP or HTTPS.")}catch{errors.push("Evidence URL is invalid.")}}
 if(evidence?.verified && (!evidence.verifiedBy?.trim() || !evidence.verifiedAt)) errors.push("Verified evidence requires a verifier and verification timestamp.");
 return errors;
}
export function canTransition(record, nextStatus) {
 const errors=[];
 if(!STATUSES.includes(nextStatus)) return {ok:false,errors:["Unknown workflow status."]};
 if(nextStatus===record.status) return {ok:true,errors:[]};
 if(!(TRANSITIONS[record.status]||[]).includes(nextStatus)) errors.push(`Transition ${record.status} → ${nextStatus} is not permitted.`);
 if(["BLOCKED","ON_HOLD"].includes(record.status)&&nextStatus!==record.resumeStatus&&!["WITHDRAWN","CANCELLED"].includes(nextStatus)){
  errors.push(record.resumeStatus?`From ${record.status}, resume only to the recorded prior status ${record.resumeStatus}, or withdraw/cancel.`:"This legacy "+record.status+" record has no recorded resume status; add a reviewed correction before resuming.");
 }
 const evidence=record.sourceEvidence||[];
 const requirement=EVIDENCE_REQUIRED[nextStatus];
 if(requirement){
  const found=evidence.some(e=>requirement.types.includes(e.type)&&(!requirement.verified||e.verified===true));
  if(!found)errors.push(`${nextStatus} requires ${requirement.types.join(" or ")}${requirement.verified?" with recorded verification":""}.`);
 }
 if(nextStatus==="QUALIFIED"){
  const approval=(record.approvals||[]).find(a=>a.kind==="QUALIFICATION"&&a.status==="APPROVED"&&a.approvedAt&&a.approver?.trim()&&!a.revokedAt);
  if(!approval)errors.push("Qualification requires a named, active qualification approval record.");
 }
 if(nextStatus==="APPROVED_TO_SUBMIT"){
  const approval=(record.approvals||[]).find(a=>a.kind==="SUBMISSION"&&a.status==="APPROVED"&&a.approvedAt&&a.approver?.trim());
  if(!approval)errors.push("A named submission approver and approval record are required.");
  if(!evidence.some(e=>e.type==="bid_review"&&e.verified))errors.push("A verified bid review evidence record is required before approval.");
 }
 if(nextStatus==="SUBMITTED"&&record.status!=="APPROVED_TO_SUBMIT")errors.push("Submission is only permitted from APPROVED_TO_SUBMIT.");
 return {ok:errors.length===0,errors};
}
export function applyTransition(record,nextStatus,{actor,note="",at=new Date().toISOString()}={}) {
 if(!actor?.trim())throw new Error("A named actor is required to record a workflow transition.");
 const gate=canTransition(record,nextStatus);
 if(!gate.ok)throw new Error(gate.errors.join(" "));
 const event=makeAuditEvent("STATUS_TRANSITION",actor||"unspecified",{from:record.status,to:nextStatus,note},at);
 let auditTrail=[...(record.auditTrail||record.history||[]),event];
 const updated={...record,status:nextStatus,updatedAt:at,auditTrail,history:auditTrail};
 if(["BLOCKED","ON_HOLD"].includes(nextStatus)&&record.status!==nextStatus)updated.resumeStatus=record.status;
 else if(["BLOCKED","ON_HOLD"].includes(record.status)&&nextStatus===record.resumeStatus)delete updated.resumeStatus;
 if(nextStatus==="IN_PREPARATION"){
  const approvals=(updated.approvals||[]).map(a=>{
   if(a.kind==="SUBMISSION"&&a.status==="APPROVED"&&!a.revokedAt){
    const revoked={...a,status:"REVOKED",revokedAt:at};
    auditTrail=[...auditTrail,makeAuditEvent("APPROVAL_REVOKED",actor||"unspecified",{approvalId:a.id,kind:a.kind,reason:"Workflow returned to preparation; bid package must be re-reviewed."},at)];
    return revoked;
   }
   return a;
  });
  updated.approvals=approvals;updated.auditTrail=auditTrail;updated.history=auditTrail;
 }
 return updated;
}
export function addEvidence(record,evidence,{actor,at=new Date().toISOString()}={}) {
 if(!actor?.trim())throw new Error("A named actor is required to record source evidence.");
 if(evidence?.verified&&!actor.trim())throw new Error("Verified evidence requires a named verifier.");
 const normalized={...evidence,id:evidence.id||globalThis.crypto?.randomUUID?.()||`evidence-${Date.now()}`,recordedAt:at,recordedBy:actor.trim(),verifiedAt:evidence.verified?at:null,verifiedBy:evidence.verified?actor.trim():null};
 const errors=validateEvidence(normalized); if(errors.length)throw new Error(errors.join(" "));
 const event=makeAuditEvent("EVIDENCE_RECORDED",actor,{evidenceId:normalized.id,type:normalized.type,title:normalized.title,verified:!!normalized.verified,sourceUrl:normalized.sourceUrl||null,reference:normalized.reference||null,sourceFeedUrl:normalized.sourceFeedUrl||null,sourceItemId:normalized.sourceItemId||null,sourcePublishedAt:normalized.sourcePublishedAt||null,fetchedAt:normalized.fetchedAt||null,contentSha256:normalized.contentSha256||null,verifiedBy:normalized.verifiedBy||null,verifiedAt:normalized.verifiedAt||null},at);
 const auditTrail=[...(record.auditTrail||record.history||[]),event];
 const sourceTypes=["official_notice","source_page","amendment"];
 return {...record,sourceEvidence:[...(record.sourceEvidence||[]),normalized],updatedAt:at,auditTrail,history:auditTrail,lastVerifiedAt:normalized.verified&&sourceTypes.includes(normalized.type)?at:record.lastVerifiedAt||null};
}
export function approve(record,{kind="SUBMISSION",approver,scope,at=new Date().toISOString()}={}){
 if(!["QUALIFICATION","SUBMISSION"].includes(kind))throw new Error("Unsupported approval type.");
 if(!approver?.trim())throw new Error("Approver name is required.");
 if(!scope?.trim())throw new Error("Approval scope is required.");
 if(kind==="QUALIFICATION"){
  if(record.status!=="VERIFIED")throw new Error("Qualification approval is only allowed from VERIFIED.");
  if(!(record.sourceEvidence||[]).some(e=>e.type==="qualification_review"&&e.verified))throw new Error("Add a verified qualification-review evidence record before approval.");
 }else{
  if(record.status!=="VALIDATED")throw new Error("Submission approval is only allowed from VALIDATED.");
  if(!(record.sourceEvidence||[]).some(e=>e.type==="bid_review"&&e.verified))throw new Error("Add a verified bid-review evidence record before approval.");
 }
 const active=(record.approvals||[]).find(a=>a.kind===kind&&a.status==="APPROVED"&&!a.revokedAt);
 if(active)throw new Error("An active "+kind.toLowerCase()+" approval already exists; revoke it before replacing it.");
 const approval={id:globalThis.crypto?.randomUUID?.()||`approval-${Date.now()}`,kind,status:"APPROVED",approver:approver.trim(),scope:scope.trim(),approvedAt:at,revokedAt:null};
 const auditTrail=[...(record.auditTrail||record.history||[]),makeAuditEvent("APPROVAL_GRANTED",approver,{approvalId:approval.id,kind,scope:approval.scope},at)];
 const updated={...record,approvals:[...(record.approvals||[]),approval],auditTrail,history:auditTrail,updatedAt:at};
 if(kind==="QUALIFICATION"){
  updated.qualificationApproved=true;
  updated.qualificationApproval={approver:approval.approver,approvedAt:at,scope:approval.scope,approvalId:approval.id};
 }
 return updated;
}
export function createRecord(draft,{actor="user",at=new Date().toISOString()}={}) {
 const record={...draft,id:globalThis.crypto?.randomUUID?.()||`tender-${Date.now()}`,schemaVersion:SCHEMA_VERSION,status:"DISCOVERED",createdAt:at,updatedAt:at,lastVerifiedAt:null,sourceEvidence:[],approvals:[],qualificationApproved:false,auditTrail:[],history:[]};
 const auditTrail=[makeAuditEvent("RECORD_CREATED",actor,{title:record.title,sourceUrl:record.sourceUrl||null},at)];
 record.auditTrail=auditTrail;record.history=auditTrail;return record;
}

