"use strict";
(() => {
 const $ = id => document.getElementById(id);
 async function call(path, data) {
   const t = $("token").value;
   if (!t || t.length < 32) throw Error("Enter the owner session token");
   const r = await fetch(path, {method:"POST",cache:"no-store",headers:{"Content-Type":"application/json","Authorization":"Bearer "+t},body:JSON.stringify(data)});
   const j = await r.json();
   if (!r.ok) throw Error(j.error || "HTTP "+r.status);
   return j;
 }
 async function show(path, data) {
   $("status").textContent="Checking real source…";
   try {
     const r=await call(path,data);
     $("result").textContent=JSON.stringify(r,null,2);
     $("status").textContent=r.run_status||r.status||"Ready";
   } catch(e) {
     $("result").textContent="";
     $("status").textContent=e.message;
   }
 }
 $("research").addEventListener("click",()=>show("/api/research",{query:$("query").value.trim(),hours:72,limit:5}));
 $("capabilities").addEventListener("click",()=>show("/api/capabilities",{}));
 if(document.modelContext?.registerTool){
   const controller=new AbortController();
   document.modelContext.registerTool({
     name:"fama_discover_public_sources",
     description:"Discover public research leads for FAMA using the signed-in owner's local research runner. Results are not fact-checked and no content is published.",
     inputSchema:{type:"object",properties:{query:{type:"string",minLength:2,maxLength:120}},required:["query"],additionalProperties:false},
     annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:true},
     async execute({query}){
       const r=await call("/api/research",{query,hours:72,limit:5});
       return {content:[{type:"text",text:JSON.stringify(r)}]};
     },
     signal:controller.signal
   });
   window.addEventListener("pagehide",()=>controller.abort(),{once:true});
 }
})();
