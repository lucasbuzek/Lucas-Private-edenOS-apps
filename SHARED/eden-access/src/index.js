const KEY="eden.local.profile.v1";

export function localProfile(storage=globalThis.localStorage){
  let p=storage?.getItem(KEY);
  if(p) return JSON.parse(p);
  const profile={id:crypto.randomUUID(),mode:"local",createdAt:new Date().toISOString(),identity:null};
  storage?.setItem(KEY,JSON.stringify(profile));
  return profile;
}

export function personalize(profile, verifiedIdentity){
  if(!verifiedIdentity?.provider || !verifiedIdentity?.subject) throw new Error("Verified provider identity required");
  return {...profile,mode:"personalized",identity:{
    provider:verifiedIdentity.provider,
    subject:verifiedIdentity.subject,
    displayName:verifiedIdentity.displayName ?? null
  }};
}

export function requiresNetworkAuth(url, protectedPrefixes=["/api/","/sync/","/files/"]){
  const p=new URL(url,"https://eden.local").pathname;
  return protectedPrefixes.some(prefix=>p.startsWith(prefix));
}

export async function apiFetch(input, init={}){
  const r=await fetch(input,{...init,credentials:"include"});
  if(r.status===401) throw new Error("AUTH_REQUIRED");
  if(r.status===403) throw new Error("FORBIDDEN");
  return r;
}
