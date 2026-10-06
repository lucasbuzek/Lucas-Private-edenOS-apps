import http from "node:http";import fs from"node:fs";import path from"node:path";import{fileURLToPath}from"node:url";import{routeCapability}from"./router.mjs";
const here=path.dirname(fileURLToPath(import.meta.url)), pub=path.resolve(here,"../public");
const s=http.createServer(async(q,r)=>{
 if(q.url==="/health"){r.setHeader("content-type","application/json");return r.end(JSON.stringify({ok:true,branch:"B1",maturity:"EXPERIMENTAL"}));}
 if(q.method==="POST"&&q.url==="/api/route"){let b="";for await(const c of q)b+=c;r.setHeader("content-type","application/json");try{return r.end(JSON.stringify(routeCapability(JSON.parse(b||"{}"))))}catch(e){r.statusCode=400;return r.end(JSON.stringify({error:"INVALID_REQUEST"}))}}
 if(q.method==="GET"&&(q.url==="/"||q.url==="/index.html")){r.setHeader("content-type","text/html; charset=utf-8");return fs.createReadStream(path.join(pub,"index.html")).pipe(r)}
 r.statusCode=404;r.end("Not found");
});s.listen(process.env.PORT||8787,()=>console.log("MONETA Experimental http://127.0.0.1:"+(process.env.PORT||8787)));