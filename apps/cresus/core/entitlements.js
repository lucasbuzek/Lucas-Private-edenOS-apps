export function allDeclaredCapabilities(contract){
 const p=contract?.profiles?.commercial?.products||{};
 return [...new Set(Object.values(p).flat())].sort();
}

export function effectiveCapabilities({contract,buildProfile="development_alpha",ownsFull=false,intelligenceActive=false}){
 if(buildProfile==="development_alpha") return allDeclaredCapabilities(contract);
 const p=contract?.profiles?.commercial?.products||{};
 const out=new Set(p.free||[]);
 if(ownsFull) (p.full||[]).forEach(x=>out.add(x));
 if(intelligenceActive) (p.intelligence||[]).forEach(x=>out.add(x));
 return [...out].sort();
}
