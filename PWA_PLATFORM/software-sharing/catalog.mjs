import {readdirSync, lstatSync, realpathSync} from 'node:fs';
import {join, resolve, basename} from 'node:path';

const SLUG=/^[a-z][a-z0-9-]{1,58}$/;
const DISPLAY=/^[^<>&\u0000-\u001F]{2,100}$/;
const RESERVED=new Set(['#common','#in chat','#Backups']);
const NOT_APPS=new Set(['Online Plugins & Connectors','Photoshop Workflow Library','EDEN Web Portal']);

export function softwareId(name) {
  if(typeof name!=='string')throw new TypeError('Project name required');
  const result=name.normalize('NFKD').replace(/[\u0300-\u036f]/g,'')
    .toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'');
  return SLUG.test(result)?result:null;
}

/**
 * Read-only immediate-child directory discovery. Never follows symlinks, looks
 * inside projects, loads source code, or grants access because a folder exists.
 */
export function discoverSoftwareFolders(softwareRoot) {
  if(typeof softwareRoot!=='string'||!softwareRoot.trim())throw new TypeError('Software Development root required');
  const resolved=realpathSync(softwareRoot);
  if(basename(resolved)!=='Software Development')throw new Error('Only canonical Software Development directory can be scanned');
  const entries=[];
  const used=new Set();
  for(const name of readdirSync(resolved,{encoding:'utf8'}).sort((a,b)=>a.localeCompare(b))) {
    if(name.startsWith('.')||name.startsWith('#')||RESERVED.has(name))continue;
    const path=join(resolved,name);
    const stats=lstatSync(path);
    if(!stats.isDirectory()||stats.isSymbolicLink())continue;
    const id=softwareId(name);
    if(!id||used.has(id))continue;
    used.add(id);
    entries.push({
      id,name,
      classification:NOT_APPS.has(name)?'SOFTWARE_SUPPORT_FOLDER':'PROJECT_CANDIDATE',
      publication:'PRIVATE_UNREVIEWED',
      requestable:false,
      downloadable:false,
      runtimeDeployed:false,
    });
  }
  return entries;
}

/** Curated public catalog: only entries explicitly enabled for a request form. */
export function validateSharingCatalog(catalog) {
  const errors=[];
  if(!catalog||catalog.schemaVersion!==1||!Array.isArray(catalog.entries)){
    return {ok:false,errors:['Catalog v1 entries required']};
  }
  const ids=new Set();
  for(const x of catalog.entries){
    if(!x||!SLUG.test(x.id||'')||ids.has(x.id))errors.push('Duplicate/invalid application ID');
    ids.add(x?.id);
    if(!DISPLAY.test(x?.name||''))errors.push('Unsafe or missing application name');
    if(typeof x?.description!=='string'||x.description.length>260||/[<>]/.test(x.description))
      errors.push('Unsafe catalog description');
    if(x?.state!=='PLACEHOLDER_ONLY')errors.push('Catalog cannot imply a functioning release');
    if(typeof x?.requestable!=='boolean'||typeof x?.listed!=='boolean')
      errors.push('Explicit requestable and listed flags required');
    if(x?.listed===true&&x?.requestable!==true)
      errors.push('Public listings require app-specific request enablement');
    if(x?.downloadable!==false||x?.artifactUrl!==undefined||x?.sourcePath!==undefined)
      errors.push('Unverified artifacts and local source paths cannot enter sharing catalog');
    if(x?.authorizedRelease!==false)errors.push('Software release state cannot be inferred from folder discovery');
  }
  return {ok:errors.length===0,errors};
}

export function publicSharingEntries(catalog) {
  const valid=validateSharingCatalog(catalog);
  if(!valid.ok)throw new Error('Invalid private sharing catalog: '+valid.errors.join('; '));
  return catalog.entries.filter(x=>x.listed===true&&x.requestable===true)
    .map(({id,name,description,state})=>({id,name,description,state}));
}

export function validatedRequestedApp(catalog,id) {
  if(typeof id!=='string')return null;
  return publicSharingEntries(catalog).find(x=>x.id===id)||null;
}
