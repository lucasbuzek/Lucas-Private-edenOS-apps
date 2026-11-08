// ZACCHAEUS: privately entered income events with explicit evidence state.
// A recorded amount is NOT verified cash received or an official dividend source.
const respond=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:{'content-type':'application/json','cache-control':'no-store'}});
export const INCOME_STATES=Object.freeze({
  paid:'REALIZED',reconciled:'REALIZED',
  declared:'DECLARED',entitled:'DECLARED',payable:'DECLARED',
  forward_indicated:'FORWARD_INDICATED',estimated:'ESTIMATED',
  changed:'EXCEPTION',deferred:'EXCEPTION',cancelled:'EXCEPTION'
});
const SYMBOL=/^[A-Z0-9][A-Z0-9.\/_-]{0,23}$/;
const MIC=/^[A-Z0-9]{4}$/;
const CCY=/^[A-Z]{3}$/;
const AMOUNT=/^(?:0|[1-9][0-9]{0,11})(?:\.[0-9]{1,8})?$/;
const COLUMNS='id,account_label,ticker,mic,currency,amount,status,effective_at,pay_date,source_published_at,description,source_ref,notes,known_at,observed_at,updated_at,revision';
const clean=(v,max)=>typeof v==='string'?v.trim().slice(0,max+1):'';
function validDate(d){if(!/^\d{4}-\d{2}-\d{2}$/.test(d))return false;const t=new Date(d+'T00:00:00.000Z');return Number.isFinite(t.getTime())&&t.toISOString().slice(0,10)===d;}
function validate(raw){
  if(!raw||typeof raw!=='object'||Array.isArray(raw))return {error:'Provide a dividend or income event'};
  const accountLabel=clean(raw.accountLabel===undefined?'Manual':raw.accountLabel,80);
  const ticker=clean(raw.ticker,24).toUpperCase();
  const mic=clean(raw.mic,4).toUpperCase();
  const currency=clean(raw.currency,3).toUpperCase();
  const amount=clean(raw.amount,32);
  const status=clean(raw.status,24).toLowerCase();
  const effectiveAt=clean(raw.effectiveAt,10);
  const payDate=clean(raw.payDate,10);
  const sourcePublishedAt=clean(raw.sourcePublishedAt,10);
  const description=clean(raw.description,160);
  const sourceRef=clean(raw.sourceRef,500);
  const notes=clean(raw.notes,2000);
  if(!accountLabel||accountLabel.length>80)return {error:'Account label must be 1–80 characters'};
  if(!SYMBOL.test(ticker))return {error:'Invalid ticker or symbol'};
  if(mic&&!MIC.test(mic))return {error:'MIC must be exactly four characters when supplied'};
  if(!CCY.test(currency))return {error:'Three-letter currency required'};
  if(!AMOUNT.test(amount))return {error:'Amount must be a non-negative exact decimal string (up to 8 places)'};
  if(!Object.hasOwn(INCOME_STATES,status))return {error:'Unknown income evidence state'};
  if(!validDate(effectiveAt))return {error:'Valid ISO effective date required'};
  if(payDate&&!validDate(payDate))return {error:'Invalid pay date'};
  if(sourcePublishedAt&&!validDate(sourcePublishedAt))return {error:'Invalid source publication date'};
  if(description.length>160||sourceRef.length>500||notes.length>2000)return {error:'Description, source or notes too long'};
  return {accountLabel,ticker,mic,currency,amount,status,effectiveAt,payDate,sourcePublishedAt,description,sourceRef,notes};
}
const owned=(env,email,id)=>env.DB.prepare(`SELECT ${COLUMNS} FROM income_events WHERE id=? AND email=?`).bind(id,email).first();
function atomic(s){const [i,f='']=s.split('.');return BigInt(i)*100000000n+BigInt((f+'00000000').slice(0,8));}
function decimal(n){const i=n/100000000n;const frac=(n%100000000n).toString().padStart(8,'0').replace(/0+$/,'');return i.toString()+(frac?'.'+frac:'');}
function summarize(events){
  const groups=new Map();
  for(const e of events){
    const key=e.currency+'|'+INCOME_STATES[e.status];
    groups.set(key,(groups.get(key)||0n)+atomic(e.amount));
  }
  return [...groups].map(([k,v])=>{const [currency,basis]=k.split('|');return {currency,basis,amount:decimal(v)};})
    .sort((a,b)=>a.currency.localeCompare(b.currency)||a.basis.localeCompare(b.basis));
}
export async function handleIncome(request,env,email,path){
  if(path==='/api/income'){
    if(request.method==='GET'){
      const {results}=await env.DB.prepare(`SELECT ${COLUMNS} FROM income_events WHERE email=? ORDER BY effective_at DESC,id DESC`).bind(email).all();
      return respond({events:results.map(x=>({...x,basis:INCOME_STATES[x.status]})),totals:summarize(results),
        provenance:'manual-user-entry',verifiedCash:false,livePrices:false,fxConversion:false});
    }
    if(request.method!=='POST')return respond({error:'Method not allowed'},405);
    let raw;try{raw=await request.json()}catch{return respond({error:'Invalid JSON'},400)}
    const p=validate(raw);if(p.error)return respond({error:p.error},400);
    const id=crypto.randomUUID(),now=new Date().toISOString();
    await env.DB.prepare('INSERT INTO income_events(id,email,account_label,ticker,mic,currency,amount,status,effective_at,pay_date,source_published_at,description,source_ref,notes,known_at,observed_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)')
      .bind(id,email,p.accountLabel,p.ticker,p.mic,p.currency,p.amount,p.status,p.effectiveAt,p.payDate,p.sourcePublishedAt,p.description,p.sourceRef,p.notes,now,now).run();
    return respond({event:await owned(env,email,id)},201);
  }
  const match=path.match(/^\/api\/income\/([a-f0-9-]{36})$/i);
  if(!match)return respond({error:'Not found'},404);
  const id=match[1],prior=await owned(env,email,id);
  if(!prior)return respond({error:'Not found'},404);
  if(request.method==='DELETE'){
    await env.DB.prepare('DELETE FROM income_events WHERE email=? AND id=?').bind(email,id).run();
    return respond({ok:true});
  }
  if(request.method==='PATCH'){
    let raw;try{raw=await request.json()}catch{return respond({error:'Invalid JSON'},400)}
    if(!raw||typeof raw!=='object'||Array.isArray(raw))return respond({error:'Invalid changes'},400);
    const allowed=['amount','status','effectiveAt','payDate','sourcePublishedAt','description','sourceRef','notes'];
    const keys=Object.keys(raw);
    if(!keys.length||keys.some(x=>!allowed.includes(x)))return respond({error:'Only event amount, status, dates, description and source notes can be edited'},400);
    const revision=Number(request.headers.get('If-Match'));
    if(!Number.isSafeInteger(revision)||revision!==prior.revision)return respond({error:'Event changed; reload before editing'},409);
    const p=validate({
      accountLabel:prior.account_label,ticker:prior.ticker,mic:prior.mic,currency:prior.currency,
      amount:raw.amount===undefined?prior.amount:raw.amount,
      status:raw.status===undefined?prior.status:raw.status,
      effectiveAt:raw.effectiveAt===undefined?prior.effective_at:raw.effectiveAt,
      payDate:raw.payDate===undefined?prior.pay_date:raw.payDate,
      sourcePublishedAt:raw.sourcePublishedAt===undefined?prior.source_published_at:raw.sourcePublishedAt,
      description:raw.description===undefined?prior.description:raw.description,
      sourceRef:raw.sourceRef===undefined?prior.source_ref:raw.sourceRef,
      notes:raw.notes===undefined?prior.notes:raw.notes
    });
    if(p.error)return respond({error:p.error},400);
    const result=await env.DB.prepare("UPDATE income_events SET amount=?,status=?,effective_at=?,pay_date=?,source_published_at=?,description=?,source_ref=?,notes=?,updated_at=?,revision=revision+1 WHERE id=? AND email=? AND revision=?")
      .bind(p.amount,p.status,p.effectiveAt,p.payDate,p.sourcePublishedAt,p.description,p.sourceRef,p.notes,new Date().toISOString(),id,email,revision).run();
    if((result.meta?.changes??result.changes)===0)return respond({error:'Event changed; reload before editing'},409);
    return respond({event:await owned(env,email,id)});
  }
  return respond({error:'Method not allowed'},405);
}
