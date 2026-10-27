// External smoke test: real unauthenticated official Luno market endpoint.
// NO brokerage account, payment method, trading API scope or user data needed.
import {probeLunoMarket} from '../engine.mjs';
try {
  const quote=await probeLunoMarket('XBTZAR');
  if(quote.status!=='RESEARCH_ONLY'||quote.tradeAuthorized!==false)
    throw Error('Execution-isolation invariant failed');
  process.stdout.write(JSON.stringify({
    probe:'CRESUS_READ_ONLY_LUNO',result:'LIVE_READ_VERIFIED',
    asOf:quote.observedAt,instrument:quote.instrument,
    source:quote.sourceUrl,orderCapability:false
  })+'\n');
}catch(err){
  process.stderr.write('LIVE_READ_UNVERIFIED: '+String(err?.message||err)+'\n');
  process.exitCode=1;
}
