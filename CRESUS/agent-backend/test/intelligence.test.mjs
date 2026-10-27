import{test}from'node:test';
import assert from'node:assert/strict';
import{explainEvidence}from '../intelligence.mjs';
const evidence={status:'RESEARCH_ONLY',tradeAuthorized:false,instrument:'XBTZAR',
  bid:'100',ask:'101',spreadPercent:0.99,observedAt:new Date().toISOString(),
  sourceUrl:'https://api.luno.com/api/1/ticker?pair=XBTZAR',warnings:['Fees not verified']};
test('agent optional real API adapter cannot gain trade tools or alter deterministic input',async()=>{
 let request;
 const result=await explainEvidence(evidence,{apiKey:'mock-secret',model:'testing-model',
  fetchFn:async(url,opts)=>{
   request={url,opts,body:JSON.parse(opts.body)};
   return{ok:true,json:async()=>({output:[{content:[{type:'output_text',text:'Spread and fees need review.'}]}]})};
  }});
 assert.equal(request.url,'https://api.openai.com/v1/responses');
 assert.equal(request.body.store,false);
 assert.deepEqual(request.body.tools,[]);
 assert.equal(request.body.input.includes('mock-secret'),false);
 assert.equal(result.tradeAuthorized,false);
 assert.equal(result.classification,'AI_INFERENCE_NOT_VERIFIED_FACT');
 assert.match(result.explanation,/fees/);
});
test('model only operates on verified quote; missing credentials fail before fetch',async()=>{
 await assert.rejects(()=>explainEvidence({...evidence,tradeAuthorized:true},{apiKey:'a',model:'b'}));
 await assert.rejects(()=>explainEvidence(evidence,{apiKey:'',model:'b'}));
 await assert.rejects(()=>explainEvidence(evidence,{apiKey:'a',model:'b',lens:'TRADE_NOW'}));
});
