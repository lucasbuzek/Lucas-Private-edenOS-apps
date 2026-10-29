import test from "node:test";
import assert from "node:assert/strict";
import {createRecord,migrateWorkspace} from "../src/workflow.js";
import {addComplianceRequirement,setComplianceState,linkComplianceEvidence,complianceSummary} from "../src/compliance.js";
const seed=()=>createRecord({title:"Real notice under review",contextId:"private",serviceMode:"supplier"},{actor:"tester",at:"2026-10-29T09:00:00Z"});
test("adds a requirement without changing tender or qualification status",()=>{
 let r=seed(), original=r.status;
 r=addComplianceRequirement(r,{requirement:"Current tax-compliance certificate",actor:"tester"});
 assert.equal(r.complianceMatrix.length,1);
 assert.equal(r.complianceMatrix[0].state,"OPEN");
 assert.equal(r.status,original);
 assert.equal(r.qualificationApproved,false);
 assert.equal(r.auditTrail.at(-1).action,"COMPLIANCE_REQUIREMENT_ADDED");
});
test("rejects empty requirements and non-tender records",()=>{
 assert.throws(()=>addComplianceRequirement(seed(),{requirement:"  "}),/mandatory/);
 assert.throws(()=>addComplianceRequirement({}, {requirement:"yes"}),/record required/);
});
test("does not let user set compliance to pass/verified or link nonexistent evidence",()=>{
 let r=addComplianceRequirement(seed(),{requirement:"Proof of address"});
 const id=r.complianceMatrix[0].id;
 assert.throws(()=>setComplianceState(r,{id,state:"PASS"}),/Unrecognized/);
 assert.throws(()=>setComplianceState(r,{id,state:"EVIDENCE_LINKED"}),/Link an evidence/);
 assert.throws(()=>linkComplianceEvidence(r,{id,evidenceId:"outside-tenant-id"}),/not recorded/);
});
test("links only existing same-record evidence and permits removal without silent verification",()=>{
 let r=addComplianceRequirement(seed(),{requirement:"Relevant previous project"});
 const id=r.complianceMatrix[0].id;
 r.sourceEvidence=[{id:"e1",title:"Reference",verified:false}];
 r=linkComplianceEvidence(r,{id,evidenceId:"e1"});
 assert.equal(r.complianceMatrix[0].state,"EVIDENCE_LINKED");
 assert.equal(r.complianceMatrix[0].evidenceId,"e1");
 assert.equal(complianceSummary(r).readyForSubmission,false);
 r=linkComplianceEvidence(r,{id,evidenceId:""});
 assert.equal(r.complianceMatrix[0].state,"OPEN");
 assert.equal(r.complianceMatrix[0].evidenceId,null);
});
test("preparation state GAP or REVIEW_PENDING is auditable without creating qualification",()=>{
 let r=addComplianceRequirement(seed(),{requirement:"Professional capacity"});
 const id=r.complianceMatrix[0].id;
 r=setComplianceState(r,{id,state:"GAP",actor:"reviewer"});
 assert.equal(r.complianceMatrix[0].state,"GAP");
 assert.equal(r.auditTrail.at(-1).actor,"reviewer");
 assert.equal(r.status,"DISCOVERED");
 r=setComplianceState(r,{id,state:"REVIEW_PENDING"});
 assert.equal(complianceSummary(r).reviewPending,1);
});
test("schema v3 backup roundtrip retains matrix and traceability",()=>{
 let r=addComplianceRequirement(seed(),{requirement:"Registration",actor:"tester"});
 const backup={schemaVersion:3,records:[r],contexts:[{id:"private",name:"Private",type:"personal"}],profile:{},activeContextId:"private"};
 const v=migrateWorkspace(JSON.parse(JSON.stringify(backup)));
 assert.equal(v.records[0].complianceMatrix.length,1);
 assert.equal(v.records[0].auditTrail.at(-1).action,"COMPLIANCE_REQUIREMENT_ADDED");
});
test("summary is descriptive only and never claims independent verification",()=>{
 const d=complianceSummary(seed());assert.equal(d.total,0);assert.equal(d.independentlyVerified,false);assert.equal(d.readyForSubmission,false);
});
