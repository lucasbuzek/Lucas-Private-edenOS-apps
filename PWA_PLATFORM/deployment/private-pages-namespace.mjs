/**
 * Desired Cloudflare Pages names only; no DNS or Pages provisioning.
 * branch.project.pages.dev aliases require successful independent branch preview deployments.
 * Branch aliases are NOT separate Cloudflare Pages projects or Access applications.
 */
export const PRIVATE_PAGES_PROJECT = 'edenosprivate';
export const PORTAL_PAGES_PROJECT = 'edenosportal';

const RESERVED = Object.freeze([
  {label:'Lucas',branch:'lucas',kind:'owner-admin',access:'owner-only',appId:null},
  {label:'HERMES',branch:'hermes',kind:'standalone-app-entry',access:'approved-app-testers',appId:'hermes'},
  {label:'CRESUS',branch:'cresus',kind:'standalone-app-entry',access:'approved-app-testers',appId:'cresus'},
  {label:'Elysium',branch:'elysium',kind:'future-environment',access:'owner-only-until-authorized',appId:null},
  {label:'Slindokuhle',branch:'slindokuhle',kind:'future-environment',access:'owner-only-until-authorized',appId:null},
  {label:'LucasTesting',branch:'lucastesting',kind:'future-environment',access:'owner-only-until-authorized',appId:null},
]);

function branchLabel(value) {
  if(typeof value!=='string'||!/^[a-z][a-z0-9-]{1,48}$/.test(value)) {
    throw new TypeError('Pages branch names must be stable lowercase DNS-safe labels');
  }
  return value;
}
export function plannedBranchAlias(branch, project=PRIVATE_PAGES_PROJECT) {
  branchLabel(branch);
  if(!/^[a-z][a-z0-9-]{2,48}$/.test(project))throw new TypeError('Invalid Pages project name');
  return 'https://'+branch+'.'+project+'.pages.dev';
}

/** Reuse for future apps while retaining app-owned identity and data. */
export function planPrivatePagesNamespace({additionalAppIds=[]}={}) {
  if(!Array.isArray(additionalAppIds))throw new TypeError('additionalAppIds must be a list');
  const entries=RESERVED.map(x=>({...x}));
  for(const id of additionalAppIds) {
    const branch=branchLabel(id);
    if(entries.some(e=>e.branch===branch))throw new Error('Duplicate or reserved environment: '+branch);
    entries.push({label:branch,branch,kind:'standalone-app-entry',access:'approved-app-testers',appId:branch});
  }
  const environments=entries.map(entry=>({
    ...entry,project:PRIVATE_PAGES_PROJECT,requestedUrl:plannedBranchAlias(entry.branch),
    pagesAliasKind:'branch-preview-alias',
    availability:'UNVERIFIED_NOT_PROVISIONED',accessAccepted:false,deployed:false,
    gates:{
      exactCloudflareProject:'UNKNOWN',branchPreview:'UNKNOWN',cloudflareAccess:'UNKNOWN',
      branchAndHashPreviewProtection:'UNKNOWN',ownerOrAppMembership:'UNKNOWN',
      directOriginBypass:'UNKNOWN',
    },
    appIsolation:entry.appId?'separate-app-runtime-data-and-identity-required':'separate-environment-authorization-required',
    placeholderOnly:true,actualApplicationDeployedHere:false,
  }));
  return {
    schemaVersion:1,status:'DESIRED_NAMES_ONLY',namespace:PRIVATE_PAGES_PROJECT,
    privateRoot:'https://'+PRIVATE_PAGES_PROJECT+'.pages.dev',
    securityRequirements:{
      privateRootRequiresAccess:true,
      allBranchAliasesRequireAccess:true,
      allImmutablePreviewUrlsRequireAccess:true,
      lucasOwnerAdminOnly:true,
      independentApplicationMembership:true,
      directOriginBypassMustBeBlocked:true,
      separatelyHostedPortal:true,
      physicalAcceptanceRequired:true,
    },
    environments,
    futurePortal:{
      label:'edenOS portal',project:PORTAL_PAGES_PROJECT,
      requestedUrl:'https://'+PORTAL_PAGES_PROJECT+'.pages.dev',
      kind:'future-unified-portal-placeholder',
      availability:'UNVERIFIED_NOT_PROVISIONED',deployed:false,
      productionPublicationAllowed:false,
    },
    criticalBoundaries:[
      'Branch aliases on one Pages project are not separate Pages projects',
      'Protect the project root, all branch aliases and immutable hash preview URLs',
      'Each standalone app retains separate backend, data, Access membership and release approval',
      'Protect or disable direct Workers, custom-domain and Pages origins bypassing the gateway',
      'Do not auto-publish placeholders, production branches or create Cloudflare resources',
    ],
  };
}

export function validatePrivatePagesNamespace(plan) {
  const errors=[];
  if(!plan||plan.schemaVersion!==1||plan.namespace!==PRIVATE_PAGES_PROJECT) {
    return {ok:false,errors:['Unknown private Pages namespace schema']};
  }
  const requirements=plan.securityRequirements || {};
  for(const key of ['privateRootRequiresAccess','allBranchAliasesRequireAccess',
    'allImmutablePreviewUrlsRequireAccess','lucasOwnerAdminOnly',
    'independentApplicationMembership','directOriginBypassMustBeBlocked',
    'separatelyHostedPortal','physicalAcceptanceRequired']) {
    if(requirements[key]!==true)errors.push('Private Pages Access/security requirement missing: '+key);
  }
  if(plan.status!=='DESIRED_NAMES_ONLY')errors.push('Static plan must not claim actual deployment status');
  const branches=new Set(),apps=new Set(),urls=new Set();
  if(!Array.isArray(plan.environments)||plan.environments.length<RESERVED.length) {
    errors.push('Established private environment entries required');
  } else {
    for(const env of plan.environments) {
      try {
        branchLabel(env.branch);
        if(env.requestedUrl!==plannedBranchAlias(env.branch))errors.push('Unrecognized alias: '+env.branch);
      } catch{errors.push('Invalid Pages alias');}
      if(branches.has(env.branch))errors.push('Duplicate Pages branch: '+env.branch);
      branches.add(env.branch);
      if(urls.has(env.requestedUrl))errors.push('Duplicate host: '+env.requestedUrl);
      urls.add(env.requestedUrl);
      if(env.project!==PRIVATE_PAGES_PROJECT)errors.push('Environment escaped namespace');
      if(!['owner-only','approved-app-testers','owner-only-until-authorized'].includes(env.access)) {
        errors.push('Unsafe access profile: '+env.branch);
      }
      if(env.appId) {
        if(apps.has(env.appId))errors.push('Duplicate app identity: '+env.appId);
        apps.add(env.appId);
        if(env.kind!=='standalone-app-entry'||env.access!=='approved-app-testers') {
          errors.push('Standalone app policy altered: '+env.branch);
        }
      }
      if(env.deployed!==false||env.accessAccepted!==false ||
         env.placeholderOnly!==true||env.actualApplicationDeployedHere!==false) {
        errors.push('Static entry cannot claim a deployed app, provisioning or acceptance');
      }
    }
    for(const reserved of RESERVED) {
      const actual=plan.environments.find(e=>e.branch===reserved.branch);
      if(!actual||actual.kind!==reserved.kind||actual.access!==reserved.access||
         actual.appId!==reserved.appId)errors.push('Canonical environment altered: '+reserved.branch);
    }
  }
  if(plan.futurePortal?.requestedUrl!=='https://edenosportal.pages.dev'||
     plan.futurePortal?.project!==PORTAL_PAGES_PROJECT||
     plan.futurePortal?.deployed!==false||
     plan.futurePortal?.productionPublicationAllowed!==false) {
    errors.push('Future portal must remain a separate unpublished Pages project intent');
  }
  return {ok:errors.length===0,errors};
}

/** Informational placeholder only, no account, login, gateway or external asset. */
export function renderUnpublishedPlaceholder(name) {
  const entry=RESERVED.find(e=>e.branch===name);
  const portal=name==='edenosportal';
  if(!entry&&!portal)throw new Error('Unknown pre-approved placeholder');
  const title=portal?'edenOS Portal':entry.label;
  const note=portal?'Future unified edenOS portal. Not launched.'
    :entry.kind==='owner-admin'?'Reserved owner administration environment. Access not activated.'
    :entry.kind==='standalone-app-entry'?'Independent private application. Owner-approved testing only. Not launched.'
    :'Reserved future private environment. Not launched.';
  return '<!doctype html><html lang="en"><head><meta charset="utf-8">'+
    '<meta name="viewport" content="width=device-width,initial-scale=1">'+
    '<meta name="robots" content="noindex,nofollow,noarchive">'+
    '<meta http-equiv="Content-Security-Policy" content="default-src &#39;none&#39;; style-src &#39;unsafe-inline&#39;; base-uri &#39;none&#39;; form-action &#39;none&#39;">'+
    '<title>'+title+' — private preview</title>'+
    '<style>body{font-family:system-ui,sans-serif;background:#f6f7f9;color:#242832;max-width:42rem;margin:12vh auto;padding:2rem}main{border:1px solid #d7dbe2;border-radius:16px;padding:2rem;background:#fff}small{color:#626979}</style>'+
    '</head><body><main><h1>'+title+'</h1><p>'+note+'</p>'+
    '<small>Development placeholder only. No account or Access policy is active.</small></main></body></html>\n';
}
