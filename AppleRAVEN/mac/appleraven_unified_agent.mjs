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
import {createHash} from "node:crypto";
import {createInterface} from "node:readline";
const exec=promisify(execFile);
const BASE=path.join(os.homedir(),".config","appleraven");
const REGISTRY=path.join(BASE,"providers.json");
const ENDPOINT="https://appleraven-device.lucasravensnest.workers.dev";
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
  {name:"blender_python",description:"Run a saved Blender Python script in background after Mac confirmation.",inputSchema:{type:"object",properties:{script_path:{type:"string"}},required:["script_path"]}}
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
