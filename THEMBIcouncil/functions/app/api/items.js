import {authorize,json} from "../../_lib/auth.js";
const kinds=new Set(["task","note","file"]);
const validId=id=>typeof id==="string"&&/^[0-9a-f]{8}-[0-9a-f-]{27,36}$/.test(id);
const now=()=>Date.now();
const sizeOk=v=>new TextEncoder().encode(v).length<=60000;
export async function onRequest(context){
 const a=await authorize(context);if(a.error)return a.error;
 const req=context.request,db=context.env.COUNCIL_DB,owner=a.user.email;
 if(req.method==="GET"){
  const kind=new URL(req.url).searchParams.get("kind");
  if(kind&&!kinds.has(kind))return json({error:"invalid_kind"},400);
  const stmt=kind?db.prepare("SELECT id,kind,title,body,done,mime,size,version,created_at,updated_at FROM council_items WHERE principal=?1 AND kind=?2 ORDER BY updated_at DESC LIMIT 200").bind(owner,kind):db.prepare("SELECT id,kind,title,body,done,mime,size,version,created_at,updated_at FROM council_items WHERE principal=?1 ORDER BY updated_at DESC LIMIT 200").bind(owner);
  const rows=await stmt.all();return json({items:rows.results||[],limit:200});
 }
 if(!["POST","PATCH","DELETE"].includes(req.method))return json({error:"method_not_allowed"},405);
 let b;try{if(Number(req.headers.get("Content-Length")||0)>100000)return json({error:"too_large"},413);b=await req.json()}catch{return json({error:"invalid_json"},400)}
 if(!b||typeof b!=="object"||Array.isArray(b))return json({error:"invalid_input"},400);
 if(req.method==="POST"){
  const kind=b.kind,title=String(b.title||"").trim(),body=String(b.body||"");
  if(!kinds.has(kind)||!title||title.length>180||!sizeOk(title)||!sizeOk(body))return json({error:"invalid_item"},400);
  const id=crypto.randomUUID(),ts=now(),mime=kind==="file"?"text/plain":"text/plain";
  await db.prepare("INSERT INTO council_items(id,principal,kind,title,body,mime,size,created_at,updated_at) VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9)").bind(id,owner,kind,title,body,mime,new TextEncoder().encode(body).length,ts,ts).run();
  return json({id,kind,title,body,version:1,done:0,created_at:ts,updated_at:ts},201);
 }
 const id=b.id,version=Number(b.version);
 if(!validId(id)||!Number.isInteger(version)||version<1)return json({error:"id_and_version_required"},400);
 if(req.method==="DELETE"){
  if(b.confirm!==true)return json({error:"confirmation_required"},400);
  const result=await db.prepare("DELETE FROM council_items WHERE id=?1 AND principal=?2 AND version=?3").bind(id,owner,version).run();
  if(!result.meta?.changes)return json({error:"missing_or_version_conflict"},409);
  return json({deleted:true,id});
 }
 const row=await db.prepare("SELECT kind,title,body,done,version FROM council_items WHERE id=?1 AND principal=?2").bind(id,owner).first();
 if(!row||row.version!==version)return json({error:"missing_or_version_conflict"},409);
 const title=b.title===undefined?row.title:String(b.title).trim(),body=b.body===undefined?row.body:String(b.body);
 const done=b.done===undefined?row.done:b.done===true?1:b.done===false?0:-1;
 if(!title||title.length>180||done<0||!sizeOk(title)||!sizeOk(body))return json({error:"invalid_item"},400);
 const ts=now(),size=new TextEncoder().encode(body).length;
 const result=await db.prepare("UPDATE council_items SET title=?1,body=?2,done=?3,size=?4,updated_at=?5,version=version+1 WHERE id=?6 AND principal=?7 AND version=?8").bind(title,body,done,size,ts,id,owner,version).run();
 if(!result.meta?.changes)return json({error:"version_conflict"},409);
 return json({id,title,body,done,version:version+1,updated_at:ts});
}
