/**
 * Deterministic read-only Action boundary. BIFROST remains the owner of
 * capability discovery, connections, credentials, authorization transport
 * and actual execution. Each specialist App owns its business permissions.
 * Inject trusted server-only adapters; never accept browser-defined tools.
 */
const APP_ID=/^[a-z][a-z0-9-]{1,58}$/;
const CONNECTION_ID=/^[A-Za-z0-9][A-Za-z0-9_.:-]{1,127}$/;
const REPOSITORY=/^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}\/[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$/;
const ACTIONS=Object.freeze({
  'github.repository.metadata':{
    validate:args=>REPOSITORY.test(args?.repository||'') &&
      args.repository.split('/').every(part=>part!=='.'&&part!=='..'&&!part.endsWith('.')),
    publicRequest:args=>({repository:args.repository}),
    summarize:(data,args)=>{
      if(typeof data?.private!=='boolean'||typeof data?.default_branch!=='string'||
        data.default_branch.length>150)throw new Error('Unverified repository metadata');
      return {repository:args.repository,private:data.private,defaultBranch:data.default_branch};
    },
  },
  'dropbox.folder.list':{
    validate:args=>{
      const path=args?.folder;
      if(typeof path!=='string'||path.length<1||path.length>512||
        !(path.startsWith('/')||/^ns:[0-9]+\/\//.test(path)))return false;
      if(/[?#\x00-\x1f]/.test(path))return false;
      const body=path.replace(/^ns:[0-9]+\/\//,'/');
      return body.split('/').every(segment=>segment!=='.'&&segment!=='..');
    },
    publicRequest:args=>({folder:args.folder}),
    summarize:(data,args)=>{
      if(!Array.isArray(data?.entries)||data.entries.length>50)
        throw new Error('Invalid or oversized folder listing');
      const entries=data.entries.map(item=>{
        if(!item||typeof item.name!=='string'||item.name.length>200||
          !['file','folder'].includes(item.type))throw new Error('Malformed folder item');
        return {name:item.name,type:item.type};
      });
      return {folder:args.folder,count:entries.length,entries};
    },
  },
});
export function readonlyActionNames(){return Object.keys(ACTIONS);}

export function createReadOnlyActionBridge({appActions,authorize,resolveCapability,invokeResolved}={}){
  if(!appActions||typeof appActions!=='object'||Array.isArray(appActions)||
    typeof authorize!=='function'||typeof resolveCapability!=='function'||
    typeof invokeResolved!=='function')
    throw new TypeError('Trusted app grants, BIFROST resolution and invocation are required');
  const registered=Object.create(null);
  for(const [appId,bindings] of Object.entries(appActions)){
    if(!APP_ID.test(appId)||!bindings||typeof bindings!=='object'||Array.isArray(bindings))
      throw new TypeError('Invalid app-specific action bindings');
    for(const [actionId,capabilityId] of Object.entries(bindings)){
      if(!Object.hasOwn(ACTIONS,actionId)||typeof capabilityId!=='string'||
        !/^[a-z][a-z0-9.-]{2,127}$/.test(capabilityId))
        throw new TypeError('Unknown or unsafe BIFROST read-only capability binding');
    }
    registered[appId]=Object.freeze({...bindings});
  }
  const refuse=reason=>({state:'DENIED',reason});
  return Object.freeze({
    async run({principal,appId,actionId,connectionId,args}={}){
      if(typeof principal?.id!=='string'||!principal.id.trim()||
        !Array.isArray(principal.allowedApps)||!principal.allowedApps.includes(appId)||
        !APP_ID.test(appId||''))return refuse('APP_LOGIN_REQUIRED');
      const action=Object.hasOwn(ACTIONS,actionId)?ACTIONS[actionId]:null;
      const capability=registered[appId]?.[actionId];
      if(!action||!capability)return refuse('READ_ONLY_ACTION_NOT_DECLARED');
      if(!CONNECTION_ID.test(connectionId||'')||!action.validate(args))
        return refuse('INVALID_ACTION_ARGUMENTS');
      let grant;
      try{grant=await authorize({principal,appId,actionId,connectionId,args});}catch{}
      // Client "consent:true" is not trusted. The app-owned grant must bind
      // this exact app, Action, connection AND resource.
      const resource=args.repository||args.folder;
      if(grant?.allowed!==true||grant.appId!==appId||
        grant.actionId!==actionId||grant.connectionId!==connectionId||
        grant.resource!==resource||grant.mode!=='read-only')
        return refuse('EXPLICIT_APP_SCOPED_GRANT_REQUIRED');
      let resolved;
      try{resolved=await resolveCapability({principal,appId,capability,connectionId});}catch{}
      if(resolved?.state!=='AVAILABLE'||resolved.capability!==capability||
        resolved.connectionId!==connectionId||resolved.readOnly!==true||
        resolved.connected!==true||resolved.accepted!==true)
        return {state:'UNAVAILABLE',reason:'BIFROST_CAPABILITY_UNVERIFIED'};
      let raw;
      try{raw=await invokeResolved({principal,appId,actionId,capability,connectionId,
        args:action.publicRequest(args),resolution:resolved});}
      catch{return {state:'UNAVAILABLE',reason:'READ_ONLY_PROVIDER_EXECUTION_FAILED'};}
      try{
        return {state:'COMPLETED',appId,actionId,connectionId,
          data:action.summarize(raw,args),providerAcceptance:'UNVERIFIED_LIVE'};
      }catch{return {state:'UNAVAILABLE',reason:'READ_ONLY_RESULT_UNVERIFIED'};}
    },
  });
}
