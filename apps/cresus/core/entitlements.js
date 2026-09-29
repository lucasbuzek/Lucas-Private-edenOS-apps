export function effectiveCapabilities({free=[],full=[],intelligence=[],ownsFull=false,intelligenceActive=false}){
 const out=new Set(free);
 if(ownsFull) full.forEach(x=>out.add(x));
 if(intelligenceActive) intelligence.forEach(x=>out.add(x));
 return [...out].sort();
}
