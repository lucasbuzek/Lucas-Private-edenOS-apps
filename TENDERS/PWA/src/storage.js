import { migrateWorkspace, SCHEMA_VERSION, STATUSES } from "./workflow.js";
import { PRIVATE_CONTEXT_ID, recordContextId, scopedRecords, validContextId, WORK_MODES } from "./workModes.js";
export const STORAGE_KEYS={records:"tenders-records-v1",profile:"tenders-profile-v1",workspace:"tenders-workspace-v2",workspaceV3:"tenders-workspace-v3",uiMode:"tenders-ui-mode"};
export function readWorkspace(storage=localStorage) {
 const v3=storage.getItem(STORAGE_KEYS.workspaceV3);
 if(v3)return migrateWorkspace(JSON.parse(v3));
 const v2=storage.getItem(STORAGE_KEYS.workspace);
 if(v2)return migrateWorkspace(JSON.parse(v2));
 const legacyRecords=JSON.parse(storage.getItem(STORAGE_KEYS.records)||"[]");
 const legacyProfile=JSON.parse(storage.getItem(STORAGE_KEYS.profile)||"null");
 return migrateWorkspace({schemaVersion:1,records:legacyRecords,profile:legacyProfile});
}
export function writeWorkspace(workspace,storage=localStorage) {
 const migrated=migrateWorkspace({...workspace,schemaVersion:SCHEMA_VERSION});
 // Write canonical schema 3 first; rollback keys remain private-only and schema-2-readable.
 storage.setItem(STORAGE_KEYS.workspaceV3,JSON.stringify(migrated));
 const privateRecords=scopedRecords(migrated.records,PRIVATE_CONTEXT_ID).map(r=>({...r,schemaVersion:2}));
 const personalProfile=migrated.profilesByContext[PRIVATE_CONTEXT_ID]||{organisation:"",sectors:"",geography:"",registrations:""};
 storage.setItem(STORAGE_KEYS.workspace,JSON.stringify({schemaVersion:2,records:privateRecords,profile:personalProfile}));
 storage.setItem(STORAGE_KEYS.records,JSON.stringify(privateRecords));
 storage.setItem(STORAGE_KEYS.profile,JSON.stringify(personalProfile));
 return migrated;
}
export function validateBackup(value) {
 if(!value||typeof value!=="object"||!Array.isArray(value.records)||!value.profile)throw new Error("Backup format not recognised.");
 if(value.records.some(r=>!r||typeof r!=="object"||(r.status&&!STATUSES.includes(r.status))||(r.serviceMode&&!WORK_MODES[r.serviceMode])||(r.contextId&&!validContextId(r.contextId))))throw new Error("Backup includes an invalid tender record.");
 const migrated=migrateWorkspace(value);
 const available=new Set(migrated.contexts.map(c=>c.id));
 if(migrated.records.some(r=>!available.has(recordContextId(r))))throw new Error("Backup refers to an undeclared workspace context.");
 return migrated;
}

