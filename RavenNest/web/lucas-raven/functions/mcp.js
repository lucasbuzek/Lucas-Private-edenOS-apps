// RAVENsNEST remote MCP: read-only file tools on existing per-user grants.
// Stateless 2026-07-28 plus 2025-11-25 handshake compatibility.
// Authoritative file permissions remain in api/files.js, never in model input.
// This endpoint is NOT a replacement for browser WebMCP, and is NOT production-paired.
import {onRequest as filesRequest} from './api/files.js';
const NEW='2026-07-28', OLD='2025-11-25',MAX_BODY=16384;
const BASE={'content-type':'application/json; charset=utf-8','cache-control':'private, no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer'};
const out=(body,status=200,extra={})=>new Response(JSON.stringify(body),{status,headers:{...BASE,...extra}});
const error=(id,code,message,status=400)=>out({jsonrpc:'2.0',id,error:{code,message}},status);
const reply=(id,result)=>out({jsonrpc:'2.0',id,result:{resultType:'complete',...result}});
const TOOLS=[
 {name:'raven_files_providers',title:'Approved file sources',description:'List only explicitly authorized storage sources for the signed-in user. No credentials or files are returned.',inputSchema:{type:'object',properties:{},additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:true}},
 {name:'raven_files_list',title:'List approved folder',description:'List one folder in a granted source. Use the returned encrypted cursor to continue pagination; never guess other users\' locations.',inputSchema:{type:'object',properties:{source:{type:'string',minLength:2,maxLength:49},path:{type:'string',maxLength:1024},cursor:{type:'string',maxLength:9000}},required:['source'],additionalProperties:false},annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:true}}
];
function allowedOrigin(request,env){
 const origin=request.headers.get('origin');if(!origin)return true;
 const own=new URL(request.url).origin;
 if(origin===own)return true;
 return String(env.RAVEN_MCP_ALLOWED_ORIGINS||'').split(',').map(x=>x.trim()).filter(Boolean).includes(origin);
}
async function invokeFiles(request,env,params){
 const url=new URL('/api/files',request.url);
 for(const [key,value] of Object.entries(params))if(value!==null&&value!==undefined)url.searchParams.set(key,value);
 // Reuse exact existing authorization service. Do not forward Origin, cookies,
 // Authorization or arbitrary client-supplied headers to provider routes.
 const headers=new Headers();
 const access=request.headers.get('cf-access-jwt-assertion');
 if(access)headers.set('cf-access-jwt-assertion',access);
 return filesRequest({request:new Request(url,{method:'GET',headers}),env});
}
function validArguments(name,args){
 if(!args||typeof args!=='object'||Array.isArray(args))return false;
 const keys=Object.keys(args);
 if(name==='raven_files_providers')return keys.length===0;
 if(name!=='raven_files_list'||keys.some(x=>!['source','path','cursor'].includes(x)))return false;
 return typeof args.source==='string'&&/^[a-z][a-z0-9_-]{1,48}$/.test(args.source)
  &&(args.path===undefined||typeof args.path==='string'&&args.path.length<=1024)
  &&(args.cursor===undefined||typeof args.cursor==='string'&&args.cursor.length<=9000);
}
async function handler(request,env){
 if(!allowedOrigin(request,env))return out({error:'cross-origin denied'},403);
 if(request.method==='GET'||request.method==='DELETE')return new Response(null,{status:405,headers:{...BASE,allow:'POST'}});
 if(request.method!=='POST')return new Response(null,{status:405,headers:{...BASE,allow:'POST'}});
 const len=Number(request.headers.get('content-length')||0);
 if(len>MAX_BODY)return error(null,-32600,'Request too large',413);
 const type=(request.headers.get('content-type')||'').split(';')[0].trim().toLowerCase();
 if(type!=='application/json')return error(null,-32600,'Content-Type must be application/json',415);
 let payload;
 try{
  const raw=await request.text();
  if(raw.length>MAX_BODY)return error(null,-32600,'Request too large',413);
  payload=JSON.parse(raw);
 }catch{return error(null,-32700,'Parse error')}
 if(!payload||typeof payload!=='object'||Array.isArray(payload)||payload.jsonrpc!=='2.0'||typeof payload.method!=='string')return error(null,-32600,'Invalid request');
 const id=payload.id;
 if(id!==undefined&&id!==null&&(typeof id!=='string'&&typeof id!=='number'||typeof id==='number'&&!Number.isFinite(id)))return error(null,-32600,'Invalid request id');
 const modern=payload.method!=='initialize'&&request.headers.get('mcp-protocol-version')===NEW;
 const legacy=payload.method==='initialize'||request.headers.get('mcp-protocol-version')===OLD||(!request.headers.has('mcp-protocol-version')&&payload.method!=='server/discover');
 if(!modern&&!legacy)return error(id??null,-32600,'Unsupported MCP protocol version');
 if(modern){
  const meta=payload.params?._meta;
  if(meta?.['io.modelcontextprotocol/protocolVersion']!==NEW||request.headers.get('mcp-method')!==payload.method||
   (payload.method==='tools/call'&&request.headers.get('mcp-name')!==payload.params?.name))return error(id??null,-32600,'MCP header and request metadata mismatch');
 }
 if(payload.method==='notifications/initialized'&&legacy)return new Response(null,{status:202,headers:{'cache-control':'no-store'}});
 if(id===undefined||id===null)return error(null,-32600,'Request id required');
 // All private metadata and tool calls require a valid, enrolled identity.
 // Probe only the already-authorized source registry: no external file access.
 const gate=await invokeFiles(request,env,{action:'providers'});
 if(!gate.ok)return error(id,-32001,'RAVENsNEST sign-in or enrollment required',401);
 if(payload.method==='initialize'&&legacy)return reply(id,{protocolVersion:OLD,capabilities:{tools:{}},serverInfo:{name:'ravennest-files',version:'0.1.0'}});
 if(payload.method==='server/discover'&&modern)return reply(id,{supportedVersions:[NEW,OLD],capabilities:{tools:{}},instructions:'Only approved storage sources. Read-only; never infer access beyond explicit grants.',_meta:{'io.modelcontextprotocol/serverInfo':{name:'ravennest-files',version:'0.1.0'}},ttlMs:0,cacheScope:'private'});
 if(payload.method==='tools/list')return reply(id,{tools:TOOLS,ttlMs:0,cacheScope:'private'});
 if(payload.method!=='tools/call')return error(id,-32601,'Method not found',404);
 const name=payload.params?.name,args=payload.params?.arguments??{};
 if(!TOOLS.some(x=>x.name===name))return error(id,-32601,'Tool not found',404);
 if(!validArguments(name,args))return error(id,-32602,'Invalid tool arguments');
 const r=await invokeFiles(request,env,name==='raven_files_providers'?{action:'providers'}:{action:'list',source:args.source,path:args.path||'/',cursor:args.cursor||null});
 let result;try{result=await r.json()}catch{result={error:'File source unavailable'}}
 const safeResult=r.ok?result:{error:result.error||'File source unavailable'};
 return reply(id,{content:[{type:'text',text:JSON.stringify(safeResult)}],structuredContent:safeResult,isError:!r.ok});
}
export async function onRequest({request,env}){
 try{return await handler(request,env)}catch{return error(null,-32603,'Internal error',500)}
}
