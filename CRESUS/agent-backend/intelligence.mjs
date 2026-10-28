// Optional, replaceable LLM interpretation. All investment numbers originate from the
// deterministic CRESUS evidence adapter; the model can only annotate read-only facts.
const LENSES=new Set(['SUMMARY','RISKS','CHALLENGE']);
export async function explainEvidence(report,{lens='SUMMARY',apiKey,model,fetchFn=fetch}={}){
 if(!report||report.status!=='RESEARCH_ONLY'||report.tradeAuthorized!==false)
   throw Error('Only validated read-only evidence can be interpreted.');
 if(!LENSES.has(lens))throw Error('Unknown intelligence lens.');
 if(!apiKey||!model)throw Error('AI reasoning provider not configured; no model request made.');
 const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),15000);
 try{
  const evidence={
   instrument:report.instrument,bid:report.bid,ask:report.ask,
   spreadPercent:report.spreadPercent,observedAt:report.observedAt,
   sourceUrl:report.sourceUrl,status:report.status,warnings:report.warnings,
  };
  const r=await fetchFn('https://api.openai.com/v1/responses',{
   method:'POST',signal:controller.signal,
   headers:{authorization:'Bearer '+apiKey,'content-type':'application/json'},
   body:JSON.stringify({
    model,store:false,max_output_tokens:500,tools:[],
    instructions:'You are the optional CRESUS evidence challenger. Work strictly from the structured quote provided. Do not invent financial facts, dividends, fees or profits. Identify uncertainty, liquidity/spread and missing information. No financial order, instruction to buy/sell, account action or claim of brokerage connectivity. The deterministic engine owns all numbers.',
    input:JSON.stringify({task:lens,evidence}),
   }),
  });
  if(!r.ok)throw Error('AI provider returned HTTP '+r.status);
  const data=await r.json();
  const messages=Array.isArray(data.output)?data.output.flatMap(x=>
   Array.isArray(x.content)?x.content.filter(y=>y.type==='output_text').map(y=>y.text):[]):[];
  const prose=(typeof data.output_text==='string'?data.output_text:messages.join('\n')).trim();
  if(!prose||prose.length>20000)throw Error('AI provider returned no suitable bounded explanation.');
  return {lens,explanation:prose,classification:'AI_INFERENCE_NOT_VERIFIED_FACT',
   inputEvidence:evidence,model,tradeAuthorized:false,toolsAvailable:[],brokerConnected:false};
 }finally{clearTimeout(timeout);}
}
