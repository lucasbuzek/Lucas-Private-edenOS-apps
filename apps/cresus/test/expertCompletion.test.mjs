import test from "node:test";import assert from "node:assert/strict";
import {completionState,nextResearchQueue} from "../core/expertCompletion.js";

test("Expert cannot synthesize asymmetric evidence",()=>{
 const securities=["A","B"];
 const fields=["identity","price","priceAsOf","fundamentals","balanceSheet","income","dividend","dividendDates","valuation","riskDrivers","recentEvents","sources"];
 const observations=fields.map(field=>({securityId:"A",field,status:"verified"})).concat(fields.filter(x=>x!=="price").map(field=>({securityId:"B",field,status:"verified"})));
 const s=completionState(securities,observations);
 assert.equal(s.maySynthesize,false);
 assert.deepEqual(nextResearchQueue(s),[{securityId:"B",field:"price",retry:0,changeSource:false}]);
});

test("retry changes source after a failed attempt",()=>{
 const s={matrix:[{securityId:"B",missing:["price"]}]};
 assert.equal(nextResearchQueue(s,[{securityId:"B",field:"price",outcome:"failed"}])[0].changeSource,true);
});

test("exhausted evidence remains incomplete and never silently synthesizes",()=>{
 const securities=["B"]; const observations=[];
 const attempts=[
 "identity","price","priceAsOf","fundamentals","balanceSheet","income","dividend","dividendDates","valuation","riskDrivers","recentEvents","sources"
 ].map(field=>({securityId:"B",field,outcome:"exhausted"}));
 const s=completionState(securities,observations,attempts);
 assert.equal(s.complete,false); assert.equal(s.exhausted,true); assert.equal(s.maySynthesize,false);
});
