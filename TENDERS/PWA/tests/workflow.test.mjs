import test from "node:test";
import assert from "node:assert/strict";
import {addEvidence,approve,applyTransition,canTransition,createRecord,migrateWorkspace,validateEvidence} from "../src/workflow.js";
import {readWorkspace,writeWorkspace,validateBackup} from "../src/storage.js";
function base(){return createRecord({title:"Test tender",buyer:"Test buyer",reference:"R-1",sourceUrl:"https://example.gov/tender/1",sector:"General supplies",deadline:"",notes:""},{actor:"test",at:"2026-01-01T00:00:00.000Z"})}
function evidence(record,type,verified=true){return addEvidence(record,{type,title:type,sourceUrl:"https://example.gov/evidence/1",reference:"EV-1",verified},{actor:"reviewer",at:"2026-01-01T01:00:00.000Z"})}
test("new records carry version, source evidence, approval ledger and append-only audit",()=>{const r=base();assert.equal(r.schemaVersion,3);assert.equal(r.status,"DISCOVERED");assert.equal(r.auditTrail[0].action,"RECORD_CREATED");assert.deepEqual(r.sourceEvidence,[]);assert.deepEqual(r.approvals,[])});
test("schema v1 migrates without dropping legacy history or evidence",()=>{const v=migrateWorkspace({schemaVersion:1,records:[{id:"legacy",title:"Old",evidence:[{type:"source_page",title:"old evidence",sourceUrl:"https://example.gov",at:"2025-01-01"}],history:[{status:"DISCOVERED",at:"2025-01-01",note:"legacy"}]}],profile:{organisation:"Org"}});assert.equal(v.schemaVersion,3);assert.equal(v.records[0].sourceEvidence.length,1);assert.equal(v.records[0].auditTrail[0].action,"LEGACY_STATUS_EVENT");assert.equal(v.profile.organisation,"Org")});
test("verification requires verified official source evidence",()=>{const r=base();assert.equal(canTransition(r,"VERIFIED").ok,false);const withUnverified=addEvidence(r,{type:"source_page",title:"Notice",sourceUrl:"https://example.gov",verified:false},{actor:"user"});assert.equal(canTransition(withUnverified,"VERIFIED").ok,false);const verified=evidence(r,"official_notice");assert.equal(canTransition(verified,"VERIFIED").ok,true)});
test("illegal transitions are rejected",()=>{const r=base();assert.match(canTransition(r,"AWARDED").errors.join(" "),/not permitted/);assert.throws(()=>applyTransition(r,"SUBMITTED",{actor:"user"}),/not permitted/)});
test("qualification and bid preparation require evidence and explicit approval",()=>{let r=evidence(base(),"official_notice");r=applyTransition(r,"VERIFIED",{actor:"reviewer"});assert.equal(canTransition(r,"QUALIFIED").ok,false);r=evidence(r,"qualification_review");assert.equal(canTransition(r,"QUALIFIED").ok,false);r=approve(r,{kind:"QUALIFICATION",approver:"Lucas",scope:"Eligibility and bid/no-bid review",at:"2026-01-01T02:00:00Z"});assert.equal(canTransition(r,"QUALIFIED").ok,true);r=applyTransition(r,"QUALIFIED",{actor:"reviewer"});r=applyTransition(r,"IN_PREPARATION",{actor:"user"});r=evidence(r,"bid_review");r=applyTransition(r,"VALIDATED",{actor:"reviewer"});assert.equal(canTransition(r,"APPROVED_TO_SUBMIT").ok,false);r=approve(r,{approver:"Lucas",scope:"Final bid package and price",at:"2026-01-02T00:00:00Z"});assert.equal(canTransition(r,"APPROVED_TO_SUBMIT").ok,true);r=applyTransition(r,"APPROVED_TO_SUBMIT",{actor:"Lucas"});assert.equal(canTransition(r,"SUBMITTED").ok,false);r=evidence(r,"submission_receipt");assert.equal(canTransition(r,"SUBMITTED").ok,true)});
test("award, contract, delivery and closeout require matching evidence",()=>{let r=base();r={...r,status:"AWAITING_DECISION"};assert.equal(canTransition(r,"AWARDED").ok,false);r=evidence(r,"award_notice",false);assert.equal(canTransition(r,"AWARDED").ok,true);r=applyTransition(r,"AWARDED",{actor:"reviewer"});assert.equal(canTransition(r,"CONTRACT_ACTIVE").ok,false);r=evidence(r,"contract",false);r=applyTransition(r,"CONTRACT_ACTIVE",{actor:"reviewer"});assert.equal(canTransition(r,"DELIVERY_COMPLETE").ok,false);r=evidence(r,"delivery_acceptance",false);r=applyTransition(r,"DELIVERY_COMPLETE",{actor:"reviewer"});assert.equal(canTransition(r,"CLOSED").ok,false);r=evidence(r,"closeout_record",false);assert.equal(canTransition(r,"CLOSED").ok,true)});
test("evidence validation requires identifiable source and verifier for verified items",()=>{assert.ok(validateEvidence({type:"source_page",title:"x",verified:true}).length);assert.ok(validateEvidence({type:"source_page",title:"x",sourceUrl:"https://example.gov",verified:true}).length);assert.equal(validateEvidence({type:"source_page",title:"x",sourceUrl:"https://example.gov",verified:true,verifiedBy:"reviewer",verifiedAt:"2026-01-01"}).length,0)});
test("workspace storage migrates old keys and writes v2 while preserving rollback keys",()=>{const m=new Map([["tenders-records-v1",JSON.stringify([{id:"old",title:"Old"}])],["tenders-profile-v1",JSON.stringify({organisation:"Org"})]]);const s={getItem:k=>m.get(k)??null,setItem:(k,v)=>m.set(k,v)};const w=readWorkspace(s);assert.equal(w.schemaVersion,3);assert.equal(w.records[0].title,"Old");writeWorkspace(w,s);assert.ok(m.has("tenders-workspace-v2"));assert.equal(JSON.parse(m.get("tenders-records-v1"))[0].title,"Old");assert.equal(validateBackup(JSON.parse(m.get("tenders-workspace-v2"))).schemaVersion,3)});
test("newer backup schema is refused safely",()=>{assert.throws(()=>validateBackup({schemaVersion:99,records:[],profile:{}}),/newer than supported/)});

test("qualification boolean alone cannot bypass named approval ledger",()=>{let r=evidence(base(),"official_notice");r=applyTransition(r,"VERIFIED",{actor:"reviewer"});r=evidence(r,"qualification_review");r={...r,qualificationApproved:true};assert.equal(canTransition(r,"QUALIFIED").ok,false);assert.match(canTransition(r,"QUALIFIED").errors.join(" "),/named, active qualification approval record/);});

test("BLOCKED and ON_HOLD cannot be used to bypass forward workflow gates",()=>{
 let r=base();r=applyTransition(r,"ON_HOLD",{actor:"user"});assert.equal(r.resumeStatus,"DISCOVERED");
 assert.equal(canTransition(r,"QUALIFIED").ok,false);
 r=applyTransition(r,"DISCOVERED",{actor:"user"});assert.equal(r.resumeStatus,undefined);
 let v=evidence(base(),"official_notice");v=applyTransition(v,"VERIFIED",{actor:"reviewer"});v=applyTransition(v,"BLOCKED",{actor:"user"});
 assert.equal(canTransition(v,"IN_PREPARATION").ok,false);
 assert.equal(canTransition(v,"VERIFIED").ok,true);
});
test("returning to preparation revokes prior submission approval with audit evidence",()=>{
 let r=evidence(base(),"official_notice");r=applyTransition(r,"VERIFIED",{actor:"reviewer"});
 r=evidence(r,"qualification_review");r=approve(r,{kind:"QUALIFICATION",approver:"Lucas",scope:"Eligibility"});
 r=applyTransition(r,"QUALIFIED",{actor:"reviewer"});r=applyTransition(r,"IN_PREPARATION",{actor:"user"});
 r=evidence(r,"bid_review");r=applyTransition(r,"VALIDATED",{actor:"reviewer"});
 r=approve(r,{kind:"SUBMISSION",approver:"Lucas",scope:"Final bid and price"});
 r=applyTransition(r,"APPROVED_TO_SUBMIT",{actor:"Lucas"});
 r=applyTransition(r,"IN_PREPARATION",{actor:"Lucas"});
 assert.equal(r.approvals.find(a=>a.kind==="SUBMISSION").status,"REVOKED");
 assert.ok(r.auditTrail.some(a=>a.action==="APPROVAL_REVOKED"));
 assert.equal(canTransition(r,"APPROVED_TO_SUBMIT").ok,false);
});
test("only primary tender source evidence updates lastVerifiedAt",()=>{
 let r=evidence(base(),"bid_review");assert.equal(r.lastVerifiedAt,null);
 r=evidence(r,"source_page");assert.equal(r.lastVerifiedAt,"2026-01-01T01:00:00.000Z");
});

test("auditable events and evidence cannot be recorded without a named actor",()=>{
 const r=base();
 assert.throws(()=>applyTransition(r,"BLOCKED"),/named actor/);
 assert.throws(()=>addEvidence(r,{type:"source_page",title:"Notice",sourceUrl:"https://example.gov",verified:false}),/named actor/);
 assert.throws(()=>addEvidence(r,{type:"source_page",title:"Notice",sourceUrl:"https://example.gov",verified:true},{actor:""}),/named actor/);
});
test("evidence audit event snapshots source provenance and content hash",()=>{
 const r=addEvidence(base(),{type:"source_page",title:"Official notice",sourceUrl:"https://example.gov/t/1",reference:"R-1",sourceFeedUrl:"https://example.gov/feed",sourceItemId:"I-1",fetchedAt:"2026-10-15T00:00:00Z",contentSha256:"a".repeat(64),verified:false},{actor:"feed-adapter"});
 const event=r.auditTrail.at(-1);
 assert.equal(event.action,"EVIDENCE_RECORDED");assert.equal(event.detail.sourceFeedUrl,"https://example.gov/feed");assert.equal(event.detail.sourceItemId,"I-1");assert.equal(event.detail.contentSha256,"a".repeat(64));
});

