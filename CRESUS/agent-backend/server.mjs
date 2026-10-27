import http from 'node:http';
import {DatabaseSync} from 'node:sqlite';
import {randomUUID,timingSafeEqual} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
import {PROVIDERS,ONBOARDING_STEPS,createPlan,advancePlan,probeLunoMarket} from './engine.mjs';
// Dedicated Node backend, NOT an order-enabled broker or a Cloudflare Worker.
export function createBackend({token,dbPath=':memory:',fetchFn=fetch,clock=Date.now}={}){
  if(typeof token!=='string'||token.length<24) throw Error('Secure CRESUS_BACKEND_TOKEN (24+ characters) required.');
  const db=new DatabaseSync(dbPath);
  db.exec([
    'PRAGMA busy_timeout=5000;',
    'CREATE TABLE IF NOT EXISTS onboarding(id TEXT PRIMARY KEY,plan_json TEXT NOT NULL,updated_at TEXT NOT NULL);',
    'CREATE TABLE IF NOT EXISTS audit(seq INTEGER PRIMARY KEY AUTOINCREMENT,onboarding_id TEXT NOT NULL,event TEXT NOT NULL,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);',
    'CREATE INDEX IF NOT EXISTS audit_by_plan ON audit(onboarding_id,seq);'
  ].join('\n'));
  const json=(res,status,data)=>{
    res.writeHead(status,{'content-type':'application/json; charset=utf-8',
      'cache-control':'no-store','x-content-type-options':'nosniff'});
    res.end(JSON.stringify(data));
  };
  const authorized=req=>{
    const value=req.headers.authorization||'',expected='Bearer '+token;
    return value.length===expected.length&&timingSafeEqual(Buffer.from(value),Buffer.from(expected));
  };
  const readJson=async req=>{
    if(!String(req.headers['content-type']||'').includes('application/json')) throw Error('JSON required.');
    let size=0;const chunks=[];
    for await(const chunk of req){size+=chunk.length;if(size>16384)throw Error('Request too large.');chunks.push(chunk);}
    let body;try{body=JSON.parse(Buffer.concat(chunks).toString('utf8'));}catch{throw Error('Invalid JSON.');}
    if(!body||typeof body!=='object'||Array.isArray(body))throw Error('JSON object required.');
    return body;
  };
  const fields=(obj,keys)=>{for(const k of Object.keys(obj))if(!keys.includes(k))
    throw Error('Unexpected field: payment, identity and credential data are prohibited.');};
  const audit=(id,event)=>db.prepare('INSERT INTO audit(onboarding_id,event) VALUES(?,?)').run(id,event);
  const handler=async(req,res)=>{
    try{
      const url=new URL(req.url,'http://localhost'),path=url.pathname;
      if(path==='/healthz'&&req.method==='GET')
        return json(res,200,{service:'CRESUS_AGENT_BACKEND',status:'RUNNING',mode:'NONTRADING_STAGING',
          brokerConnected:false,liveOrderCapability:false,store:'SQLITE_REQUIRES_DURABLE_VOLUME'});
      if(!authorized(req))return json(res,401,{error:'Authenticated backend gateway required.'});
      if(path==='/v1/providers'&&req.method==='GET')
        return json(res,200,{providers:PROVIDERS,execution:'DISABLED',virtualCardAccepted:'NOT_VERIFIED'});
      if(path==='/v1/onboarding'&&req.method==='POST'){
        const body=await readJson(req);fields(body,['provider','spendingLimitUSD']);
        const plan=createPlan(body),id=randomUUID();
        db.prepare('INSERT INTO onboarding(id,plan_json,updated_at) VALUES(?,?,?)')
          .run(id,JSON.stringify(plan),new Date(clock()).toISOString());
        audit(id,'CREATED_WITHOUT_FUNDS');
        return json(res,201,{id,plan,nextStep:ONBOARDING_STEPS[0],verified:false});
      }
      const match=path.match(/^\/v1\/onboarding\/([a-f0-9-]{36})(\/attest|\/audit)?$/i);
      if(match){
        const id=match[1],suffix=match[2]||'';
        const row=db.prepare('SELECT plan_json FROM onboarding WHERE id=?').get(id);
        if(!row)return json(res,404,{error:'Session not found.'});
        const plan=JSON.parse(row.plan_json);
        if(!suffix&&req.method==='GET')
          return json(res,200,{id,plan,nextStep:ONBOARDING_STEPS[plan.stageIndex]||null,
            verified:false,notice:'Steps are user-reported, not broker-verified.'});
        if(suffix==='/audit'&&req.method==='GET')
          return json(res,200,{events:db.prepare('SELECT seq,event,created_at FROM audit WHERE onboarding_id=? ORDER BY seq').all(id)});
        if(suffix==='/attest'&&req.method==='POST'){
          const body=await readJson(req);fields(body,['step']);
          const update=advancePlan(plan,body.step);
          db.prepare('UPDATE onboarding SET plan_json=?,updated_at=? WHERE id=?')
            .run(JSON.stringify(update),new Date(clock()).toISOString(),id);
          audit(id,'USER_REPORTED_'+body.step);
          return json(res,200,{id,plan:update,nextStep:ONBOARDING_STEPS[update.stageIndex]||null,
            verified:false,liveTradeAllowed:false});
        }
      }
      if(path==='/v1/research/quote'&&req.method==='POST'){
        const body=await readJson(req);fields(body,['pair']);
        const report=await probeLunoMarket(body.pair,fetchFn);
        return json(res,200,{report,executionEnabled:false,
          nextAction:'Check fees, actual available funds, FX and authorization externally.'});
      }
      if(path.startsWith('/v1/orders')||path.startsWith('/v1/execute')||path.startsWith('/v1/automation/start'))
        return json(res,403,{error:'LIVE_EXECUTION_NOT_IMPLEMENTED'});
      return json(res,404,{error:'Not found.'});
    }catch(e){
      const message=String(e?.message||e);
      const upstream=/Market provider returned|fetch failed|abort/i.test(message);
      return json(res,upstream?502:422,{error:upstream?'Read-only market provider unavailable.':message});
    }
  };
  return {server:http.createServer(handler),db,close(){db.close();}};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href){
  if(process.env.NODE_ENV==='production'&&!process.env.CRESUS_DB_PATH)
    throw Error('Persistent CRESUS_DB_PATH is required in production.');
  const {server}=createBackend({token:process.env.CRESUS_BACKEND_TOKEN,
    dbPath:process.env.CRESUS_DB_PATH||':memory:'});
  server.listen(Number(process.env.PORT||4179),process.env.HOST||'127.0.0.1',
    ()=>process.stdout.write('CRESUS backend ready: no live orders supported\n'));
}
