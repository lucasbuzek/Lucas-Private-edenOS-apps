#!/usr/bin/env node
// AppleRAVEN private compatibility and command-injection repair for the owner's
// explicitly requested MIT npm package JoshuaRileyDev/mac-apps-launcher v0.0.1.
// The published bin points to missing dist/index.js; run dist/src/index.js.
// Never execute caller arguments in a shell. No external network here.
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
const sourceDir=process.argv[2];
if(!sourceDir||!path.isAbsolute(sourceDir))throw new Error("Absolute local source directory required.");
const root=path.join(sourceDir,"node_modules","@joshuarileydev","mac-apps-launcher-mcp-server");
const metadata=JSON.parse(fs.readFileSync(path.join(root,"package.json"),"utf8"));
if(metadata.version!=="0.0.1")throw new Error("Unreviewed launcher package version; refusing to patch.");
const entry=path.join(root,"dist","src","index.js");
let body=fs.readFileSync(entry,"utf8");
const changes=[["import { exec } from 'child_process';","import { execFile } from 'child_process';"],["const execAsync = promisify(exec);","const execAsync = promisify(execFile);"],["        await execAsync(`open \"${appPath}\"`);","        if (!(await listApplications()).includes(fullAppName)) return false;\n        await execAsync(\"/usr/bin/open\", [appPath]);"],["        await execAsync(`open -a \"${appPath}\" \"${filePath}\"`);","        if (!(await listApplications()).includes(fullAppName) || !filePath.startsWith(\"/\")) return false;\n        await execAsync(\"/usr/bin/open\", [\"-a\", appPath, filePath]);"]];
let changed=false;
for(const [original,replacement] of changes){
  const count=body.split(original).length-1;
  if(count===1){body=body.replace(original,replacement);changed=true;}
  else if(count===0&&!body.includes(replacement))throw new Error("Unexpected launcher source; refusing to enable unpatched execution.");
  else if(count>1)throw new Error("Ambiguous launcher source.");
}
if(changed)fs.writeFileSync(entry,body,{mode:0o644});
if(body.includes("execAsync(`open"))throw new Error("Shell-based launch remains; refusing provider.");
const config=path.join(os.homedir(),".config","appleraven","providers.json");
if(fs.existsSync(config)){
  const data=JSON.parse(fs.readFileSync(config,"utf8"));
  if(!Array.isArray(data.providers))throw new Error("Invalid source-provider registry.");
  let launch=data.providers.find(x=>x.key==="applaunch");
  if(!launch){launch={key:"applaunch"};data.providers.push(launch);}
  launch.command=process.execPath;launch.args=[entry];
  const pyapple=path.join(os.homedir(),"Library","Application Support","AppleRAVEN","Unified","python","bin","pyapple-mcp");
  if(fs.existsSync(pyapple)&&!data.providers.some(x=>x.key==="pyapple"))data.providers.push({key:"pyapple",command:pyapple,args:[]});
  fs.writeFileSync(config,JSON.stringify(data,null,2)+"\n",{mode:0o600});
}
console.log("AppleRAVEN launcher source verified, shell invocation removed, registry updated.");
