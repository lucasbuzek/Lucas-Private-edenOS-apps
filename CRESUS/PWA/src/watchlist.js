// CRESUS deterministic, owner-scoped watchlist records.
// A watchlist is a research collection, not a quote, a position, or an order.
const respond=(value,status=200)=>new Response(JSON.stringify(value),{status,headers:{'content-type':'application/json','cache-control':'no-store'}});
const SYMBOL=/^[A-Z0-9][A-Z0-9.\/_-]{0,23}$/;
const MIC=/^[A-Z0-9]{4}$/;
const CCY=/^[A-Z]{3}$/;
const ISIN=/^[A-Z]{2}[A-Z0-9]{9}[0-9]$/;

function clean(value,max){return typeof value==='string' ? value.trim().slice(0,max+1) : '';}
function checkCreate(raw){
  if(!raw||typeof raw!=='object'||Array.isArray(raw)) return {error:'Provide a security listing object'};
  const ticker=clean(raw.ticker,24).toUpperCase();
  const mic=clean(raw.mic,4).toUpperCase();
  const currency=clean(raw.currency,3).toUpperCase();
  const isin=clean(raw.isin,12).toUpperCase();
  const name=clean(raw.name,120);
  const notes=clean(raw.notes,2000);
  if(!SYMBOL.test(ticker))return {error:'Ticker must be 1–24 letters/numbers or supported listing separators'};
  if(mic&&!MIC.test(mic))return {error:'MIC must be exactly four characters or omitted when unknown'};
  if(currency&&!CCY.test(currency))return {error:'Currency must be three letters or omitted when unknown'};
  if(isin&&!ISIN.test(isin))return {error:'ISIN format invalid; leave blank if unknown'};
  if(name.length>120||notes.length>2000)return {error:'Name or research notes too long'};
  return {ticker,mic,currency,isin,name,notes};
}
export async function handleWatchlist(request,env,email,path){
  if(request.method==='GET'&&path==='/api/watchlist'){
    const {results}=await env.DB.prepare('SELECT id,ticker,mic,currency,isin,name,notes,created_at,updated_at FROM watchlist_entries WHERE email=? ORDER BY updated_at DESC,id DESC')
      .bind(email).all();
    return respond({entries:results,pricesAvailable:false,source:'user-entered',dataPolicy:'no brokerage or market feed inferred'});
  }
  if(request.method==='POST'&&path==='/api/watchlist'){
    let raw;try{raw=await request.json()}catch{return respond({error:'Invalid JSON'},400)}
    const row=checkCreate(raw);
    if(row.error)return respond({error:row.error},400);
    const id=crypto.randomUUID();
    try{
      await env.DB.prepare('INSERT INTO watchlist_entries(id,email,ticker,mic,currency,isin,name,notes) VALUES(?,?,?,?,?,?,?,?)')
        .bind(id,email,row.ticker,row.mic,row.currency,row.isin,row.name,row.notes).run();
    }catch(e){
      if(/UNIQUE constraint/i.test(String(e)))return respond({error:'This symbol/MIC is already in your watchlist'},409);
      throw e;
    }
    const item=await env.DB.prepare('SELECT id,ticker,mic,currency,isin,name,notes,created_at,updated_at FROM watchlist_entries WHERE email=? AND id=?').bind(email,id).first();
    return respond({entry:item},201);
  }
  const match=path.match(/^\/api\/watchlist\/([a-f0-9-]{36})$/i);
  if(!match)return respond({error:'Not found'},404);
  const id=match[1];
  if(request.method==='DELETE'){
    const old=await env.DB.prepare('SELECT id FROM watchlist_entries WHERE id=? AND email=?').bind(id,email).first();
    if(!old)return respond({error:'Not found'},404);
    await env.DB.prepare('DELETE FROM watchlist_entries WHERE id=? AND email=?').bind(id,email).run();
    return respond({ok:true});
  }
  if(request.method==='PATCH'){
    let raw;try{raw=await request.json()}catch{return respond({error:'Invalid JSON'},400)}
    if(!raw||typeof raw!=='object'||Array.isArray(raw))return respond({error:'Invalid changes'},400);
    const keys=Object.keys(raw);
    if(!keys.length||keys.some(x=>!['name','notes'].includes(x)))return respond({error:'Only name and notes may be changed; add a new listing to change identity'},400);
    const existing=await env.DB.prepare('SELECT id,name,notes FROM watchlist_entries WHERE id=? AND email=?').bind(id,email).first();
    if(!existing)return respond({error:'Not found'},404);
    const name=Object.hasOwn(raw,'name')?clean(raw.name,120):existing.name;
    const notes=Object.hasOwn(raw,'notes')?clean(raw.notes,2000):existing.notes;
    if(name.length>120||notes.length>2000)return respond({error:'Name or notes too long'},400);
    await env.DB.prepare("UPDATE watchlist_entries SET name=?,notes=?,updated_at=datetime('now') WHERE id=? AND email=?").bind(name,notes,id,email).run();
    const item=await env.DB.prepare('SELECT id,ticker,mic,currency,isin,name,notes,created_at,updated_at FROM watchlist_entries WHERE email=? AND id=?').bind(email,id).first();
    return respond({entry:item});
  }
  return respond({error:'Method not allowed'},405);
}
