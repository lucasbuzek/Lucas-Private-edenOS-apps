export const ExpertRequiredFields=Object.freeze([
 "identity","price","priceAsOf","fundamentals","balanceSheet","income","dividend",
 "dividendDates","valuation","riskDrivers","recentEvents","sources"
]);

export function evidenceMatrix(securityIds, observations, required=ExpertRequiredFields){
 return securityIds.map(securityId=>{
   const rows=observations.filter(x=>x.securityId===securityId);
   const fields=Object.fromEntries(required.map(field=>[field,rows.some(x=>x.field===field&&x.status==="verified")]));
   const missing=required.filter(field=>!fields[field]);
   return {securityId,fields,missing,complete:missing.length===0};
 });
}

export function completionState(securityIds, observations, attempts=[]){
 const matrix=evidenceMatrix(securityIds,observations);
 const incomplete=matrix.filter(x=>!x.complete);
 const exhausted=incomplete.every(item=>item.missing.every(field=>attempts.some(a=>a.securityId===item.securityId&&a.field===field&&a.outcome==="exhausted")));
 return {matrix,complete:incomplete.length===0,exhausted:incomplete.length>0&&exhausted,maySynthesize:incomplete.length===0};
}

export function nextResearchQueue(state, attempts=[]){
 const queue=[];
 for(const row of state.matrix) for(const field of row.missing){
   const prior=attempts.filter(a=>a.securityId===row.securityId&&a.field===field);
   if(!prior.some(a=>a.outcome==="exhausted")) queue.push({securityId:row.securityId,field,retry:prior.length,changeSource:prior.length>0});
 }
 return queue;
}
