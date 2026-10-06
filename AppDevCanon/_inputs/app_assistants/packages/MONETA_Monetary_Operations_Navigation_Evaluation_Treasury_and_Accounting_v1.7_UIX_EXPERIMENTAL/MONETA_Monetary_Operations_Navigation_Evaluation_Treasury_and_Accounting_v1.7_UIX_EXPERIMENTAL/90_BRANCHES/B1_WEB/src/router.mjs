const financeMap=[
  ["invoice","RECEIPT"],["receipt","RECEIPT"],["statement","RECEIPT"],
  ["transaction","MERCURY"],["payment","MERCURY"],
  ["ledger","LEDGER"],["accounting","LEDGER"],["bookkeeping","LEDGER"],
  ["budget","ALLOCATE"],["forecast","ALLOCATE"],["financial plan","ALLOCATE"],
  ["cash flow","VAULT"],["cash","VAULT"],["treasury","VAULT"],["liquidity","VAULT"],
  ["margin","MARGIN"],["profitability","MARGIN"],["pricing economics","MARGIN"],
  ["financial report","NUNTIUS"],["finance dashboard","NUNTIUS"],
  ["grant finance","PATRON"],["funding finance","PATRON"],
  ["tax","TRIBUTE"]
];
const hermesMap=["tender","rfq","rfp","job","career","freelance","opportunity","bid submission","application","recruitment","hiring"];
export function routeCapability({objective="",stage=""}={}){
  const q=String(objective).toLowerCase();
  const finance=financeMap.find(([k])=>q.includes(k));
  if(finance) return {branch:"B1",owner:finance[1],application:"MONETA",objective,stage,status:"PROPOSED",existing_solution_gate:"REQUIRED_BEFORE_IMPLEMENTATION",side_effects:"NONE"};
  const hermes=hermesMap.find(k=>q.includes(k));
  if(hermes) return {branch:"B1",owner:"HERMES",application:"HERMES",objective,stage,status:"PROPOSED",handoff_to_moneta:"WHEN_FINANCIAL_RECORD_PLAN_ADMINISTRATION_OR_ANALYSIS_BECOMES_AUTHORITATIVE",side_effects:"NONE"};
  return {branch:"B1",owner:"MONETA",application:"MONETA",objective,stage,status:"PROPOSED",existing_solution_gate:"REQUIRED_BEFORE_IMPLEMENTATION",side_effects:"NONE"};
}
