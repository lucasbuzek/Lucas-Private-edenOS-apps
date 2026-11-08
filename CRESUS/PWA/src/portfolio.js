// CRESUS manually entered positions. These records are not broker balances or fills.
// Decimal quantities and unit costs are stored as text to avoid floating-point rounding.
const respond=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:{'content-type':'application/json','cache-control':'no-store'}});
const SYMBOL=/^[A-Z0-9][A-Z0-9.\/_-]{0,23}$/;
const MIC=/^[A-Z0-9]{4}$/;
const CCY=/^[A-Z]{3}$/;
const DECIMAL=/^(?:0|[1-9][0-9]{0,11})(?:\.[0-9]{1,8})?$/;
const COLUMNS='id,account_label,ticker,mic,currency,name,quantity,unit_cost,notes,created_at,updated_at';
const clean=(v,max)=>typeof v==='string'?v.trim().slice(0,max+1):'';
const owned=(env,email,id)=>env.DB.prepare(`SELECT ${COLUMNS} FROM portfolio_positions WHERE id=? AND email=?`).bind(id,email).first();

function validate(raw){
  if(!raw||typeof raw!=='object'||Array.isArray(raw))return {error:'Provide a position object'};
  const accountLabel=clean(raw.accountLabel===undefined?'Manual':raw.accountLabel,80);
  const ticker=clean(raw.ticker,24).toUpperCase();
  const mic=clean(raw.mic,4).toUpperCase();
  const currency=clean(raw.currency,3).toUpperCase();
  const name=clean(raw.name,120);
  const notes=clean(raw.notes,2000);
  const quantity=clean(raw.quantity,32);
  const unitCost=clean(raw.unitCost,32);
  if(!accountLabel||accountLabel.length>80)return {error:'Account label must be 1–80 characters'};
  if(!SYMBOL.test(ticker))return {error:'Invalid ticker or symbol'};
  if(mic&&!MIC.test(mic))return {error:'MIC must contain four characters or be omitted'};
  if(currency&&!CCY.test(currency))return {error:'Currency must have three letters or be omitted'};
  if(!DECIMAL.test(quantity)||!/[1-9]/.test(quantity))return {error:'Quantity must be a positive decimal string (up to 8 decimal places)'};
  if(unitCost&&(!DECIMAL.test(unitCost)))return {error:'Unit cost must be a non-negative decimal string'};
  if(unitCost&&!currency)return {error:'Specify the cost currency when supplying unit cost'};
  if(name.length>120||notes.length>2000)return {error:'Name or notes too long'};
  return {accountLabel,ticker,mic,currency,name,quantity,unitCost,notes};
}

export async function handlePortfolio(request,env,email,path){
  if(path==='/api/portfolio'){
    if(request.method==='GET'){
      const {results}=await env.DB.prepare(`SELECT ${COLUMNS} FROM portfolio_positions WHERE email=? ORDER BY account_label,ticker,mic`).bind(email).all();
      return respond({positions:results,source:'manual-user-entry',livePrices:false,brokerConnected:false,transactionsVerified:false});
    }
    if(request.method!=='POST')return respond({error:'Method not allowed'},405);
    let raw;try{raw=await request.json()}catch{return respond({error:'Invalid JSON'},400)}
    const p=validate(raw);if(p.error)return respond({error:p.error},400);
    const id=crypto.randomUUID();
    try{
      await env.DB.prepare('INSERT INTO portfolio_positions(id,email,account_label,ticker,mic,currency,name,quantity,unit_cost,notes) VALUES(?,?,?,?,?,?,?,?,?,?)')
        .bind(id,email,p.accountLabel,p.ticker,p.mic,p.currency,p.name,p.quantity,p.unitCost,p.notes).run();
    }catch(e){
      if(/UNIQUE constraint/i.test(String(e)))return respond({error:'This listing already exists in that account; edit its quantity instead'},409);
      throw e;
    }
    return respond({position:await owned(env,email,id)},201);
  }
  const match=path.match(/^\/api\/portfolio\/([a-f0-9-]{36})$/i);
  if(!match)return respond({error:'Not found'},404);
  const id=match[1];
  const prior=await owned(env,email,id);
  if(!prior)return respond({error:'Not found'},404);
  if(request.method==='DELETE'){
    await env.DB.prepare('DELETE FROM portfolio_positions WHERE id=? AND email=?').bind(id,email).run();
    return respond({ok:true});
  }
  if(request.method==='PATCH'){
    let raw;try{raw=await request.json()}catch{return respond({error:'Invalid JSON'},400)}
    if(!raw||typeof raw!=='object'||Array.isArray(raw))return respond({error:'Invalid changes'},400);
    const keys=Object.keys(raw);
    if(!keys.length||keys.some(x=>!['quantity','unitCost','currency','name','notes'].includes(x)))return respond({error:'Only quantity, cost, currency, name and notes may be edited'},400);
    const merged={
      accountLabel:prior.account_label,ticker:prior.ticker,mic:prior.mic,
      currency:raw.currency===undefined?prior.currency:raw.currency,
      name:raw.name===undefined?prior.name:raw.name,
      quantity:raw.quantity===undefined?prior.quantity:raw.quantity,
      unitCost:raw.unitCost===undefined?prior.unit_cost:raw.unitCost,
      notes:raw.notes===undefined?prior.notes:raw.notes
    };
    const p=validate(merged);if(p.error)return respond({error:p.error},400);
    await env.DB.prepare("UPDATE portfolio_positions SET currency=?,name=?,quantity=?,unit_cost=?,notes=?,updated_at=datetime('now') WHERE id=? AND email=?")
      .bind(p.currency,p.name,p.quantity,p.unitCost,p.notes,id,email).run();
    return respond({position:await owned(env,email,id)});
  }
  return respond({error:'Method not allowed'},405);
}
