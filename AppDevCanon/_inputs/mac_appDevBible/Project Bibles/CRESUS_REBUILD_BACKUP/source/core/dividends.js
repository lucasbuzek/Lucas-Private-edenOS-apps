export const DividendStatus=Object.freeze({ESTIMATED:"estimated",DECLARED:"declared",ENTITLED:"entitled",PAYABLE:"payable",PAID:"paid",RECONCILED:"reconciled",CHANGED:"changed",DEFERRED:"deferred",CANCELLED:"cancelled"});
const REALIZED=new Set([DividendStatus.PAID,DividendStatus.RECONCILED]);
const DECLARED=new Set([DividendStatus.DECLARED,DividendStatus.ENTITLED,DividendStatus.PAYABLE,DividendStatus.PAID,DividendStatus.RECONCILED]);
export function dividendAmount(events,{securityId,from,to,basis="realized"}){
 const allowed=basis==="realized"?REALIZED:basis==="declared"?DECLARED:basis==="estimated"?new Set([DividendStatus.ESTIMATED]):null;
 if(!allowed) throw new Error("unsupported dividend basis");
 return events.filter(e=>e.securityId===securityId&&e.exDate>=from&&e.exDate<=to&&allowed.has(e.status)).reduce((n,e)=>n+Number(e.amount||0),0);
}
export function visibleAt(events,decisionAt){const d=Date.parse(decisionAt);if(Number.isNaN(d))throw new Error("invalid decisionAt");return events.filter(e=>{const k=Date.parse(e.knownAt);return Number.isFinite(k)&&k<=d;});}