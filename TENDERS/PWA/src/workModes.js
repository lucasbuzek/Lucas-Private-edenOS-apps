// TENDERS composable work modes. Browser-local context separation is NOT authentication.
export const PRIVATE_CONTEXT_ID = "personal-private";
export const WORK_MODES = Object.freeze({
  supplier: "Supplier / bidder",
  buyer: "Buyer / procurement authority",
  advisor: "Procurement advisor",
  representative: "Mandated representative",
  sourcing: "Sourcing / RFQ",
  contracts: "Contract & delivery",
  intelligence: "Intelligence & research",
});
export const WORK_MODE_IDS = Object.freeze(Object.keys(WORK_MODES));
export const DEFAULT_CONTEXT = Object.freeze({id:PRIVATE_CONTEXT_ID,name:"Personal · previous local records",type:"personal",jurisdiction:"",language:"en"});
const ID_FORMAT = /^[a-zA-Z0-9][a-zA-Z0-9._-]{0,79}$/;
export function validContextId(value){return typeof value==="string"&&ID_FORMAT.test(value);}
export function recordContextId(record){return validContextId(record?.contextId)?record.contextId:PRIVATE_CONTEXT_ID;}
export function scopedRecords(records,contextId){if(!validContextId(contextId))return [];return (records||[]).filter(r=>recordContextId(r)===contextId);}
export function assertSameContext(record,contextId){
 if(!validContextId(contextId)||recordContextId(record)!==contextId)throw new Error("Different workspace context: access denied.");
 return record;
}
export function normalizeContexts(contexts){
 const output=[{...DEFAULT_CONTEXT}], seen=new Set([PRIVATE_CONTEXT_ID]);
 for(const context of Array.isArray(contexts)?contexts:[]){
  if(!context||!validContextId(context.id)||seen.has(context.id)||typeof context.name!=="string"||!context.name.trim())continue;
  seen.add(context.id);
  output.push({id:context.id,name:context.name.trim().slice(0,100),type:String(context.type||"organisation"),jurisdiction:String(context.jurisdiction||""),language:String(context.language||"en")});
 }
 return output;
}
export function validateEngagementDraft(draft){
 const errors=[];
 if(!WORK_MODE_IDS.includes(draft?.serviceMode))errors.push("Choose a supported work mode.");
 if(!validContextId(draft?.contextId))errors.push("Choose a valid local workspace context.");
 if(!String(draft?.title||"").trim())errors.push("Engagement title is required.");
 return errors;
}
const RESTRICTED = new Set(["issue","submit","sign","award","pay","amend_contract","external_message","release_hold","client_export"]);
export function checkLocalAction(record,{contextId,action,now=new Date().toISOString()}={}){
 try{assertSameContext(record,contextId);}catch(error){return {ok:false,reason:error.message};}
 if(!WORK_MODE_IDS.includes(record.serviceMode||"supplier"))return {ok:false,reason:"Unknown work mode."};
 if(RESTRICTED.has(action))return {ok:false,reason:"Requires independently authenticated, action-specific authority; local browser data is insufficient."};
 if(record.status==="ON_HOLD"&&action==="approve_submission")return {ok:false,reason:"ON_HOLD is preserved until separately reviewed and authorized."};
 if(["review_buyer_evaluation","approve_buyer_award"].includes(action)){
  if(record.conflictStatus!=="CLEARED"||!record.conflictDeclarationId)return {ok:false,reason:"A documented independent conflict review is required."};
  if(record.serviceMode!=="buyer")return {ok:false,reason:"Buyer authority is required."};
  return {ok:false,reason:"Sealed buyer evaluation requires a trusted identity and authorization service."};
 }
 if(record.serviceMode==="representative"&&["approve_submission","record_submission","record_award","record_status"].includes(action)){
  const mandate=record.mandate||{};
  const valid=!!(mandate.evidenceId&&mandate.principal&&mandate.validUntil&&Number.isFinite(Date.parse(mandate.validUntil))&&Date.parse(mandate.validUntil)>=Date.parse(now)&&Array.isArray(mandate.approvedActions)&&mandate.approvedActions.includes(action));
  if(!valid)return {ok:false,reason:"Missing, expired or insufficient client mandate."};
  if(["record_submission","record_award"].includes(action))return {ok:false,reason:"Representative reporting requires independent authorization and source proof."};
 }
 if(record.conflictStatus==="FLAGGED"&&["approve_submission","record_award","review_buyer_evaluation"].includes(action))return {ok:false,reason:"Unresolved conflict of interest."};
 return {ok:true,reason:"Local preparatory action only; no provider-side authorization implied."};
}
export function requireLocalAction(record,contextId,action){const result=checkLocalAction(record,{contextId,action});if(!result.ok)throw new Error(result.reason);return true;}

export const MODE_PREPARATION_STEPS=Object.freeze({
 supplier:["Verify issuer and current notice","Check supplier registration and eligibility","Map compliance evidence","Cost bid and record reviewer","Obtain submission approval"],
 buyer:["Record procurement need and budget authority","Define RFQ/RFP specifications","Approve evaluation criteria before opening bids","Declare and review conflicts","Obtain independent award approval"],
 advisor:["Confirm client scope and advice-only boundary","Record applicable jurisdiction rules","Review onboarding and compliance gaps","Prepare client process report"],
 representative:["Identify legal principal and specific mandate","Validate mandate evidence and expiry","Check conflicts and segregation","Obtain action-specific client instruction"],
 sourcing:["Document sourcing need","Identify qualified independent suppliers","Collect comparable quotations","Record conflict and selection rationale"],
 contracts:["Verify signed contract and authority","Record contractual obligations and deadlines","Record delivery evidence","Review variations and invoices for approval"],
 intelligence:["Register official sources and permitted feeds","Check notice version and amendments","Record dates and verification state","Prepare source-attributed report"],
});
export function preparationSteps(mode){return MODE_PREPARATION_STEPS[mode]||[];}

