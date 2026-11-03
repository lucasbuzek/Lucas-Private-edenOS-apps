#!/usr/bin/env node
// AppleRAVEN unified source MCP federation (adapted from owner MacConnect source).
// Independent AppleRAVEN OAuth, pairing, endpoints; Mac-local source tool execution.
// Requires Node.js 22+ and an interactive logged-in macOS session for approvals.
import os from "node:os";
import fs from "node:fs/promises";
import path from "node:path";
import {existsSync} from "node:fs";
import {spawn,execFile} from "node:child_process";
import {promisify} from "node:util";
import {createHash,randomBytes} from "node:crypto";
import {createInterface} from "node:readline";
const exec=promisify(execFile);
const BASE=path.join(os.homedir(),".config","appleraven");
const REGISTRY=path.join(BASE,"providers.json");
const ENDPOINT=process.env.APPLERAVEN_DEVICE_ENDPOINT||"https://appleraven-device.lucasravensnest.workers.dev";
const delay=ms=>new Promise(r=>setTimeout(r,ms));
const limit=s=>String(s??"").slice(0,80000);
const definitions=[
  {name:"status",description:"System information and active Mac identity.",inputSchema:{type:"object",properties:{}}},
  {name:"list_directory",description:"List files and folders in Finder-accessible path (up to 200 entries).",inputSchema:{type:"object",properties:{path:{type:"string"}},required:["path"]}},
  {name:"read_text_file",description:"Read a text file, up to 64 KB; requires approval on the Mac.",inputSchema:{type:"object",properties:{path:{type:"string"}},required:["path"]}},
  {name:"shortcuts_list",description:"List installed Apple Shortcuts.",inputSchema:{type:"object",properties:{}}},
  {name:"shortcuts_run",description:"Run a named Apple Shortcut; requires confirmation on the Mac.",inputSchema:{type:"object",properties:{name:{type:"string"}},required:["name"]}},
  {name:"app_open",description:"Open macOS app (Xcode, Blender, Finder etc.) after local approval.",inputSchema:{type:"object",properties:{name:{type:"string"}},required:["name"]}},
  {name:"terminal",description:"Run a Terminal zsh command. Requires explicit Allow on the Mac each time.",inputSchema:{type:"object",properties:{command:{type:"string"}},required:["command"]}},
  {name:"applescript",description:"Run AppleScript/Automator automation after Mac confirmation.",inputSchema:{type:"object",properties:{script:{type:"string"}},required:["script"]}},
  {name:"xcodebuild",description:"Run xcodebuild with argument list after Mac confirmation.",inputSchema:{type:"object",properties:{args:{type:"array",items:{type:"string"}}},required:["args"]}},
  {name:"blender_python",description:"Run a saved Blender Python script in background after Mac confirmation.",inputSchema:{type:"object",properties:{script_path:{type:"string"}},required:["script_path"]}},
  {name:"file_stat",description:"Inspect file metadata and SHA-256 of a local text file up to 1 MiB, for safe edits.",inputSchema:{type:"object",properties:{path:{type:"string"}},required:["path"]}},
  {name:"write_text_file",description:"Write up to 20 KB of text, with local Mac approval and overwrite opt-in.",inputSchema:{type:"object",properties:{path:{type:"string"},content:{type:"string"},overwrite:{type:"boolean"}},required:["path","content"]}},
  {name:"make_directory",description:"Create a macOS directory with local owner approval.",inputSchema:{type:"object",properties:{path:{type:"string"}},required:["path"]}},
  {name:"move_file",description:"Move or rename a file/folder, with local approval; refuses overwrite.",inputSchema:{type:"object",properties:{from:{type:"string"},to:{type:"string"}},required:["from","to"]}},
  {name:"terminal_job_start",description:"Start a long-running Terminal job after local approval. Return durable job_id immediately; survives AppleRAVEN agent restart.",inputSchema:{type:"object",properties:{command:{type:"string"}},required:["command"]}},
  {name:"terminal_job_status",description:"Get persistent long-running job status and recent stdout/stderr.",inputSchema:{type:"object",properties:{job_id:{type:"string"}},required:["job_id"]}},
  {name:"terminal_job_cancel",description:"Request cancellation of a long-running Terminal job, after local approval.",inputSchema:{type:"object",properties:{job_id:{type:"string"}},required:["job_id"]}}
];
const commandOutput=async (command,args=[],timeout=30000)=>{
  const {stdout,stderr}=await exec(command,args,{timeout,maxBuffer:80000,encoding:"utf8",env:process.env});
  return {stdout:limit(stdout),stderr:limit(stderr),exit_code:0};
};
async function confirm(action,summary) {
  const title=String(action).replace(/[\r\n]/g," ").slice(0,120);
  const detail=String(summary).replace(/[\r\n]/g," ").slice(0,700);
  const script="display dialog "+JSON.stringify(title+"\n"+detail)+" buttons {\"Deny\", \"Allow\"} default button \"Deny\" with title \"AppleRAVEN\" giving up after 45";
  try{
    const r=await exec("osascript",["-e",script],{timeout:50000,encoding:"utf8"});
    if(!r.stdout.includes("button returned:Allow")||r.stdout.includes("gave up:true"))throw new Error("Denied");
  }catch{throw new Error("Denied or timed out on Mac. Nothing was executed.");}
}
function target(p){const s=String(p??"");if(!s||s.includes("\0"))throw new Error("Path required");return path.resolve(s.startsWith("~/")?path.join(os.homedir(),s.slice(2)):s);}
function requiredText(s,n=2000){if(typeof s!=="string"||!s.trim()||s.length>n)throw new Error("Invalid argument");return s;}
function stringArgs(a){if(!Array.isArray(a)||a.length>30||!a.every(x=>typeof x==="string"&&x.length<1024))throw new Error("Invalid argument list");return a;}

const JOB_ROOT=path.join(BASE,"jobs");
const JOB_RUNNER="const fs=require(\"node:fs\"),path=require(\"node:path\"),cp=require(\"node:child_process\");\nconst command=process.argv[1],dir=process.argv[2];\nconst output=fs.openSync(path.join(dir,\"stdout.log\"),\"a\",0o600),errors=fs.openSync(path.join(dir,\"stderr.log\"),\"a\",0o600);\nconst child=cp.spawn(\"/bin/zsh\",[\"-lc\",command],{stdio:[\"ignore\",output,errors]});\nfs.writeFileSync(path.join(dir,\"child.pid\"),String(child.pid||\"\"),{mode:0o600});\nlet requested=false;\nconst timer=setInterval(()=>{if(fs.existsSync(path.join(dir,\"cancel\"))){requested=true;child.kill(\"SIGTERM\");}},1500);\nfunction finish(state,exit_code,signal,error){clearInterval(timer);fs.writeFileSync(path.join(dir,\"status.json\"),JSON.stringify({state,exit_code,signal,error,completed_at:Date.now()}),{mode:0o600});process.exit(0)}\nchild.once(\"error\",e=>finish(\"failed\",-1,null,e.message));\nchild.once(\"close\",(code,signal)=>finish(requested?\"cancelled\":code===0?\"succeeded\":\"failed\",code,signal,null));";
const safeJobId=id=>{if(typeof id!=="string"||!/^job_[a-f0-9]{32}$/.test(id))throw new Error("Invalid job id");return id;};
async function jobRoot(id){const dir=path.join(JOB_ROOT,safeJobId(id));if(!(await fs.stat(dir).catch(()=>null))?.isDirectory())throw new Error("Unknown job");return dir;}
async function logTail(file,max=14000){
  const f=await fs.open(file,"r").catch(()=>null);if(!f)return "";
  try{const st=await f.stat(),length=Math.min(max,st.size),b=Buffer.alloc(length);await f.read(b,0,length,Math.max(0,st.size-length));return b.toString("utf8");}
  finally{await f.close();}
}
async function jobStatus(id){
  const dir=await jobRoot(id),meta=JSON.parse(await fs.readFile(path.join(dir,"meta.json"),"utf8"));
  let status=await fs.readFile(path.join(dir,"status.json"),"utf8").then(JSON.parse).catch(()=>null);
  if(!status){
    const pid=Number(await fs.readFile(path.join(dir,"runner.pid"),"utf8").catch(()=>"0"));
    if(pid){try{process.kill(pid,0)}catch{status={state:"interrupted",error:"Background runner stopped without an exit receipt"};}}
  }
  return {job_id:id,created_at:meta.created_at,command_sha256:meta.command_sha256,...(status||{state:"running"}),stdout_tail:await logTail(path.join(dir,"stdout.log")),stderr_tail:await logTail(path.join(dir,"stderr.log"))};
}
async function startJob(command){
  await fs.mkdir(JOB_ROOT,{recursive:true,mode:0o700});
  const dirs=(await fs.readdir(JOB_ROOT)).filter(n=>/^job_[a-f0-9]{32}$/.test(n));
  let active=0;for(const name of dirs.slice(-200)){const st=await jobStatus(name).catch(()=>null);if(st?.state==="running")active++;}
  if(active>=5)throw new Error("Five concurrent Mac jobs already running");
  const id="job_"+randomBytes(16).toString("hex"),dir=path.join(JOB_ROOT,id);
  await fs.mkdir(dir,{mode:0o700});
  const meta={created_at:Date.now(),command_sha256:createHash("sha256").update(command).digest("hex")};
  await fs.writeFile(path.join(dir,"meta.json"),JSON.stringify(meta),{mode:0o600});
  const runner=spawn(process.execPath,["-e",JOB_RUNNER,"--",command,dir],{detached:true,stdio:"ignore"});
  await fs.writeFile(path.join(dir,"runner.pid"),String(runner.pid||""),{mode:0o600});
  runner.unref();
  return {job_id:id,status:"started",created_at:meta.created_at,next:"terminal_job_status"};
}

async function directCall(name,arg={}) {
  switch(name){
    case "status":return {device:os.hostname(),macos:os.release(),arch:os.arch(),node:process.version,system:"macOS",uptime_seconds:Math.round(os.uptime())};
    case "list_directory":{
      const dir=target(arg.path);
      const files=await fs.readdir(dir,{withFileTypes:true});
      return {path:dir,total:files.length,entries:files.slice(0,200).map(x=>({name:x.name,type:x.isDirectory()?"folder":x.isFile()?"file":"other"}))};
    }
    case "read_text_file":{
      const file=target(arg.path);await confirm("Read Mac file",file);
      const stat=await fs.stat(file);
      if(!stat.isFile()||stat.size>65536)throw new Error("Not a text file or exceeds 64KB");
      return {path:file,content:await fs.readFile(file,"utf8")};
    }
    case "shortcuts_list":return commandOutput("/usr/bin/shortcuts",["list"],20000);
    case "shortcuts_run":{
      const shortcut=requiredText(arg.name,200);await confirm("Run Apple Shortcut",shortcut);
      return commandOutput("/usr/bin/shortcuts",["run",shortcut],60000);
    }
    case "app_open":{
      const app=requiredText(arg.name,200);await confirm("Open Mac application",app);
      return commandOutput("/usr/bin/open",["-a",app],15000);
    }
    case "terminal":{
      const command=requiredText(arg.command,600);await confirm("Execute Terminal command",command);
      try{return await commandOutput("/bin/zsh",["-lc",command],60000);}
      catch(e){return {error:e.message,stdout:limit(e.stdout),stderr:limit(e.stderr),exit_code:e.code??-1};}
    }
    case "applescript":{
      const script=requiredText(arg.script,600);await confirm("Execute AppleScript",script);
      return commandOutput("/usr/bin/osascript",["-e",script],60000);
    }
    case "xcodebuild":{
      const args=stringArgs(arg.args);if(args.join(" ").length>600)throw new Error("xcodebuild argument display limit");await confirm("Execute xcodebuild",args.join(" "));
      return commandOutput("/usr/bin/xcodebuild",args,120000);
    }
    case "blender_python":{
      const script=target(arg.script_path);await confirm("Run Blender Python script",script);
      const candidates=["/Applications/Blender.app/Contents/MacOS/Blender","/opt/homebrew/bin/blender","/usr/local/bin/blender"];
      const blender=candidates.find(existsSync);
      if(!blender)throw new Error("Blender executable not found");
      return commandOutput(blender,["--background","--python",script],120000);
    }
    case "file_stat":{
      const file=target(arg.path),st=await fs.stat(file),sha256=st.isFile()&&st.size<=1048576?createHash("sha256").update(await fs.readFile(file)).digest("hex"):null;
      return {path:file,type:st.isDirectory()?"folder":st.isFile()?"file":"other",size:st.size,modified_at:st.mtime.toISOString(),sha256};
    }
    case "write_text_file":{
      const file=target(arg.path);
      if(typeof arg.content!=="string"||Buffer.byteLength(arg.content,"utf8")>20000)throw new Error("Text content exceeds 20 KB");
      const previous=await fs.stat(file).catch(e=>{if(e.code==="ENOENT")return null;throw e});
      if(previous&&!previous.isFile())throw new Error("Existing target is not a regular file");
      if(previous&&arg.overwrite!==true)throw new Error("Existing file: set overwrite=true to request local approval");
      const digest=createHash("sha256").update(arg.content).digest("hex");
      await confirm("Write Mac text file",(previous?"OVERWRITE ":"CREATE ")+file+"; bytes="+Buffer.byteLength(arg.content)+"; SHA256="+digest);
      await fs.writeFile(file,arg.content,{flag:previous?"w":"wx",mode:0o600});
      return {path:file,bytes:Buffer.byteLength(arg.content),sha256:digest,overwrote:!!previous};
    }
    case "make_directory":{
      const dir=target(arg.path);await confirm("Create Mac directory",dir);
      await fs.mkdir(dir,{recursive:true,mode:0o700});return {path:dir,created:true};
    }
    case "move_file":{
      const from=target(arg.from),to=target(arg.to);
      await fs.lstat(from);
      if(await fs.lstat(to).then(()=>true).catch(e=>{if(e.code==="ENOENT")return false;throw e}))throw new Error("Destination exists; overwrite refused");
      await confirm("Move or rename Mac file",from+" -> "+to);
      await fs.rename(from,to);return {from,to,moved:true};
    }
    case "terminal_job_start":{
      const command=requiredText(arg.command,4000);
      await confirm("Start long-running Terminal job",command);
      return startJob(command);
    }
    case "terminal_job_status":return jobStatus(arg.job_id);
    case "terminal_job_cancel":{
      const dir=await jobRoot(arg.job_id),before=await jobStatus(arg.job_id);
      if(before.state!=="running")return {job_id:arg.job_id,status:before.state,already_finished:true};
      await confirm("Cancel Mac Terminal job",arg.job_id);
      await fs.writeFile(path.join(dir,"cancel"),"cancel\n",{flag:"w",mode:0o600});
      return {job_id:arg.job_id,status:"cancellation_requested"};
    }
    default:throw new Error("Unknown direct tool");
  }
}
class ChildMCP {
  constructor(key,command,args,cwd){this.key=key;this.command=command;this.args=args;this.cwd=cwd;this.seq=0;this.pending=new Map();}
  request(method,params,timeout=25000){
    if(!this.proc||this.proc.exitCode!==null)return Promise.reject(new Error("MCP provider is stopped"));
    const id=++this.seq;
    return new Promise((resolve,reject)=>{
      const timer=setTimeout(()=>{this.pending.delete(id);reject(new Error("MCP provider timed out"));},timeout);
      this.pending.set(id,{resolve,reject,timer});
      this.proc.stdin.write(JSON.stringify({jsonrpc:"2.0",id,method,params})+"\n");
    });
  }
  async start(){
    this.proc=spawn(this.command,this.args,{cwd:this.cwd||undefined,env:process.env,stdio:["pipe","pipe","pipe"]});
    this.proc.on("error",e=>console.error("Provider "+this.key+" failed:",e.message));
    this.proc.on("exit",()=>{for(const p of this.pending.values()){clearTimeout(p.timer);p.reject(new Error("Provider exited"));}this.pending.clear();});
    this.proc.stderr.on("data",b=>console.error("Provider "+this.key+":",String(b).slice(0,250)));
    createInterface({input:this.proc.stdout}).on("line",line=>{
      let msg;try{msg=JSON.parse(line);}catch{return;}
      if(msg.id===undefined)return;
      const pending=this.pending.get(msg.id);if(!pending)return;
      clearTimeout(pending.timer);this.pending.delete(msg.id);
      msg.error?pending.reject(new Error(msg.error.message||"MCP provider error")):pending.resolve(msg.result);
    });
    await this.request("initialize",{protocolVersion:"2025-06-18",capabilities:{},clientInfo:{name:"appleraven-unified-source-agent",version:"0.2.0"}},20000);
    this.proc.stdin.write(JSON.stringify({jsonrpc:"2.0",method:"notifications/initialized"})+"\n");
    const result=await this.request("tools/list",{},25000);
    this.tools=result.tools||[];
  }
  async call(tool,args){return this.request("tools/call",{name:tool,arguments:args},120000);}
}
const providers=[];
const providerTools=new Map();
async function setupProviders(){
  if(!existsSync(REGISTRY)){console.log("No providers.json; built-in Mac tools still available. Install source MCPs and configure ~/.config/appleraven/providers.json.");return;}
  let registry;try{registry=JSON.parse(await fs.readFile(REGISTRY,"utf8"));}catch(e){console.error("Bad providers.json:",e.message);return;}
  for(const p of registry.providers||[]){
    if(!/^[a-z][a-z0-9_]{1,18}$/.test(p.key)||typeof p.command!=="string"||!Array.isArray(p.args))continue;
    const child=new ChildMCP(p.key,p.command,p.args,p.cwd);
    try{
      await child.start();providers.push(child);
      for(const tool of child.tools){
        const normalized=String(tool.name).toLowerCase().replace(/[^a-z0-9_]/g,"_");
        const key=p.key+"__"+normalized;
        if(key.length>64||providerTools.has(key)||!tool.inputSchema)continue;
        providerTools.set(key,{child,actual:tool.name,tool:{name:key,description:"["+p.key+"] "+String(tool.description||tool.name).slice(0,400),inputSchema:tool.inputSchema}});
      }
      console.log("Connected provider",p.key,"with",child.tools.length,"tools");
    }catch(e){console.error("Provider "+p.key+" unavailable:",e.message);child.proc?.kill();}
  }
}
async function invoke(name,args) {
  if(definitions.some(t=>t.name===name))return directCall(name,args);
  const provider=providerTools.get(name);
  if(!provider)throw new Error("Unknown tool");
  const preview=JSON.stringify(args);
  if(preview.length>16000)throw new Error("Provider arguments exceed Cloudflare relay limit");
  const hash=createHash("sha256").update(preview).digest("hex");
  const summary="Tool: "+provider.actual+"; bytes: "+preview.length+"; SHA256: "+hash+"; arguments: "+(preview.length<=420?preview:preview.slice(0,220)+" [middle omitted] "+preview.slice(-100))+"; review trusted calls before allowing.";
  await confirm("Allow "+provider.child.key+" MCP tool",summary);
  return provider.child.call(provider.actual,args);
}
async function http(route,body,token){
  const response=await fetch(ENDPOINT+route,{method:"POST",headers:{"content-type":"application/json",...(token?{authorization:"Bearer "+token}:{})},body:JSON.stringify(body),signal:AbortSignal.timeout(25000)});
  const data=await response.json();
  if(!response.ok)throw new Error(route+" "+response.status+": "+String(data.error||"Request failed"));
  return data;
}
async function credentials(){
  const account=os.userInfo().username;
  let stdout;
  try{
    const r=await exec("/usr/bin/security",["find-generic-password","-s","com.lucasbuzek.appleraven.device","-a",account,"-w"],{timeout:10000,encoding:"utf8"});
    stdout=r.stdout;
  }catch{throw new Error("Mac not paired. Complete AppleRAVEN owner pairing using appleraven_agent.py --pair.");}
  const token=String(stdout||"").trim();
  if(!/^[a-f0-9]{64}$/.test(token))throw new Error("Invalid AppleRAVEN Keychain credential");
  return {device_token:token};
}
async function publishManifest(tools,token){
  await http("/v1/device/providers/register",{tools:[]},token);
  let batch=[],bytes=0,total=0;
  async function flush(){
    if(!batch.length)return;
    await http("/v1/device/providers/register",{append:true,tools:batch},token);
    total+=batch.length;batch=[];bytes=0;
  }
  for(const tool of tools){
    if(!tool||!/^[a-z][a-z0-9_]{1,63}$/.test(tool.name)||tool.inputSchema?.type!=="object")continue;
    const item={name:tool.name,description:String(tool.description||tool.name).slice(0,800),inputSchema:tool.inputSchema};
    const size=JSON.stringify(item).length;
    if(size>6500){console.error("Provider tool skipped (schema too large):",tool.name);continue;}
    if(batch.length>=35||bytes+size>85000)await flush();
    batch.push(item);bytes+=size;
  }
  await flush();
  return total;
}
async function main(){
  if(process.platform!=="darwin")throw new Error("AppleRAVEN native source agent runs only on macOS.");
  if(Number(process.versions.node.split(".")[0])<22)throw new Error("Node.js 22+ is required.");
  const creds=await credentials();
  await setupProviders();
  const tools=[...definitions,...[...providerTools.values()].map(p=>p.tool)];
  let registered=await publishManifest(tools,creds.device_token);
  console.log("AppleRAVEN source federation:",registered,"tools from native and installed MCP providers. Outbound-only; local approval required for upstream actions.");
  let failures=0,heartbeat=0;
  while(true){
    try{
      if(Date.now()-heartbeat>25000){
        await http("/v1/device/state",{hostname:os.hostname().slice(0,64),os:os.release(),capabilities:["shortcuts.list"],agent:"unified-source-0.2"},creds.device_token);
        heartbeat=Date.now();
      }
      const poll=await http("/v1/device/providers/next",{},creds.device_token);
      failures=0;
      const command=poll.command;
      if(command){
        let result,isError=false;
        try{
          result=await invoke(command.name,command.arguments||{});
          isError=result?.isError===true;
        }catch(e){result={error:String(e?.message||e)};isError=true;}
        if(JSON.stringify(result).length>150000){
          result={error:"Result exceeds current JSON relay limit; use an explicitly authorized chunked data path for large media or files."};
          isError=true;
        }
        await http("/v1/device/providers/result",{command_id:command.id,result,isError},creds.device_token);
      }else await delay(2000);
    }catch(e){
      failures++;console.error("AppleRAVEN connection:",e.message);
      if(failures===3){
        try{registered=await publishManifest(tools,creds.device_token);console.log("Re-registered",registered,"tools");}catch{}
      }
      await delay(Math.min(30000,2000*failures));
    }
  }
}
main().catch(e=>{console.error("AppleRAVEN:",e.message);process.exitCode=1;});
