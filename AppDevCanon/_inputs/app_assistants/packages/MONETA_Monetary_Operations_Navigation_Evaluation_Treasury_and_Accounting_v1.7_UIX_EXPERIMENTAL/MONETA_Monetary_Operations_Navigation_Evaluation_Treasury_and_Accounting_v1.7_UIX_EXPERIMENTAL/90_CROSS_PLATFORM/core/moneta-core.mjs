import registry from "./registry.json" with {type:"json"};
const finance=[
["invoice","RECEIPT"],["receipt","RECEIPT"],["statement","RECEIPT"],
["transaction","MERCURY"],["payment","MERCURY"],["ledger","LEDGER"],["accounting","LEDGER"],
["bookkeeping","LEDGER"],["budget","ALLOCATE"],["forecast","ALLOCATE"],["financial plan","ALLOCATE"],
["cash flow","VAULT"],["cash","VAULT"],["treasury","VAULT"],["liquidity","VAULT"],
["margin","MARGIN"],["profitability","MARGIN"],["pricing","MARGIN"],["financial report","NUNTIUS"],
["dashboard","NUNTIUS"],["grant finance","PATRON"],["funding finance","PATRON"],["tax","TRIBUTE"]];
const hermes=["tender","rfq","rfp","job","career","freelance","opportunity","bid submission","application","recruitment","hiring"];
export {registry};
export function route(objective=""){
 const q=String(objective).toLowerCase();
 const f=finance.find(([k])=>q.includes(k));
 if(f)return {application:"MONETA",owner:f[1],truth_state:"PROPOSED",side_effects:"NONE"};
 if(hermes.some(k=>q.includes(k)))return {application:"HERMES",owner:"HERMES",truth_state:"PROPOSED",handoff:"MONETA when financial record/plan/administration/analysis becomes authoritative",side_effects:"NONE"};
 return {application:"MONETA",owner:"MONETA",truth_state:"PROPOSED",side_effects:"NONE"};
}
export function resourceProfile({memoryGB=8,cores=4}={}){
 if(memoryGB>=16&&cores>=8)return {profile:"FULL",composition:"MONETA full capability composition"};
 if(memoryGB>=8&&cores>=4)return {profile:"RECOMMENDED",composition:"MONETA standard composition"};
 return {profile:"LEAN",composition:"MONETA essential surface; defer heavy providers"};
}
