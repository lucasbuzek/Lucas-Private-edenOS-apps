#!/usr/bin/env node
// Read-only live acceptance check; does not create or alter legal records.
const url = (process.env.THEMIS_URL || "https://themis-private.lucasravensnest.workers.dev").replace(/\/$/, "");
const key = process.env.THEMIS_OWNER_KEY;
if (!key) {
  console.error("Set THEMIS_OWNER_KEY in the environment; no key is bundled.");
  process.exit(2);
}
function assert(condition, reason) { if (!condition) throw new Error(reason); }
async function probe(path, options={}) {
  const response = await fetch(url + path,{redirect:"error", ...options});
  let body;
  try { body = await response.json(); } catch { throw new Error("Non-JSON response to "+path+" ("+response.status+")"); }
  return {status:response.status,body};
}
const health = await probe("/api/health");
assert(health.status===200 && health.body.ready===true,"Worker is not activated");
const blocked = await probe("/api/records");
assert(blocked.status===401,"Unauthenticated records read did not return 401");
const headers = {"Authorization":"Bearer "+key,"Content-Type":"application/json"};
const records = await probe("/api/records",{headers});
assert(records.status===200 && Array.isArray(records.body.records),"Authenticated listing failed");
const mcp = await probe("/mcp",{method:"POST",headers,body:JSON.stringify({jsonrpc:"2.0",id:1,method:"initialize",params:{protocolVersion:"2025-06-18",capabilities:{},clientInfo:{name:"themis-acceptance",version:"1"}}})});
assert(mcp.status===200 && mcp.body.result?.serverInfo?.name==="THEMIS","MCP initialization failed");
const tools = await probe("/mcp",{method:"POST",headers,body:JSON.stringify({jsonrpc:"2.0",id:2,method:"tools/list"})});
assert(tools.body.result?.tools?.length>=6,"MCP missing legal vault tools");
console.log("PASS: live owner auth, protected records, persistence service, MCP tools ("+records.body.records.length+" records)");
