"use strict";
let ownerToken="";
const el=id=>document.getElementById(id);
const locked=()=>{ownerToken=""; el("locked").style.display="block";el("work").style.display="none"};
function notice(message,error=false){el("notice").textContent=message;el("notice").className=error?"error":"muted"}
async function api(path,options={}){
 const headers=new Headers(options.headers||{});
 headers.set("Authorization","Bearer "+ownerToken);
 if(!(options.body instanceof Blob)&&options.body!==undefined)headers.set("Content-Type","application/json");
 const response=await fetch(path,{...options,headers,cache:"no-store",credentials:"omit",redirect:"error"});
 if(!response.ok){
   let message="Request failed ("+response.status+")";
   try{const d=await response.json();message=d.error||message}catch{}
   if(response.status===401||response.status===503)locked();
   throw Error(message);
 }
 return response;
}
async function refresh(){
 const search=el("search").value.trim(),kind=el("filter").value;
 const q=new URLSearchParams();if(kind)q.set("kind",kind);if(search)q.set("q",search);
 const [summaryR,itemsR]=await Promise.all([api("/api/summary"),api("/api/items?"+q)]);
 const summary=await summaryR.json(),result=await itemsR.json();
 const metrics=el("metrics");metrics.replaceChildren();
 for(const [label,count] of [["Total records",summary.total],["Needs attention",summary.needs_attention],["Due or overdue",summary.overdue],["Supplies",summary.counts.supplies]]){
   const panel=document.createElement("div");panel.className="metric";
   const strong=document.createElement("strong");strong.textContent=String(count);
   const caption=document.createElement("span");caption.textContent=label;
   panel.append(strong,caption);metrics.append(panel);
 }
 const list=el("items");list.replaceChildren();
 if(!result.items.length){const blank=document.createElement("p");blank.textContent="No records found.";list.append(blank)}
 for(const item of result.items){
   const card=document.createElement("article"),title=document.createElement("h3"),meta=document.createElement("div"),details=document.createElement("p"),actions=document.createElement("div");
   title.textContent=item.title;meta.className="muted";
   meta.textContent=[item.kind,item.status,item.location,item.due_date?(("Due "+item.due_date)):"",item.quantity!==null?("Qty "+item.quantity):""].filter(Boolean).join(" · ");
   details.textContent=item.details||"";actions.className="actions";
   const edit=document.createElement("button");edit.textContent="Edit";edit.type="button";edit.addEventListener("click",()=>editItem(item));
   const del=document.createElement("button");del.textContent="Delete";del.type="button";del.addEventListener("click",()=>removeItem(item));
   actions.append(edit,del);card.append(title,meta,details,actions);list.append(card);
 }
 notice(result.items.length+" household record(s) loaded.");
}
function editItem(item){
 const f=el("editor");for(const k of ["kind","title","status","due_date","location","details"])f.elements.namedItem(k).value=item[k]||"";
 f.elements.namedItem("ident").value=item.id;f.elements.namedItem("quantity").value=item.quantity??"";
 f.scrollIntoView({behavior:"smooth",block:"start"});f.elements.namedItem("title").focus();
}
function clearEditor(){el("editor").reset();el("editor").elements.namedItem("ident").value=""}
async function removeItem(item){
 if(!confirm("Permanently delete “"+item.title+"”?"))return;
 try{await api("/api/items/"+item.id,{method:"DELETE"});await refresh()}
 catch(e){notice(e.message,true)}
}
el("login").addEventListener("submit",async event=>{
 event.preventDefault();ownerToken=event.currentTarget.elements.namedItem("token").value;
 try{await api("/api/health");el("login").reset();el("locked").style.display="none";el("work").style.display="grid";el("work").style.gap="1rem";await refresh()}
 catch(e){notice(e.message,true)}
});
el("lock").addEventListener("click",()=>{locked();notice("Household locked.")});
el("refresh").addEventListener("click",()=>refresh().catch(e=>notice(e.message,true)));
el("clear").addEventListener("click",clearEditor);
el("search").addEventListener("change",()=>refresh().catch(e=>notice(e.message,true)));
el("filter").addEventListener("change",()=>refresh().catch(e=>notice(e.message,true)));
el("editor").addEventListener("submit",async event=>{
 event.preventDefault();const f=event.currentTarget, id=f.elements.namedItem("ident").value;
 const payload={};
 for(const key of ["kind","title","status","due_date","location","details"])payload[key]=f.elements.namedItem(key).value;
 const q=f.elements.namedItem("quantity").value;payload.quantity=q===""?null:Number(q);
 try{await api(id?"/api/items/"+id:"/api/items",{method:id?"PATCH":"POST",body:JSON.stringify(payload)});
 clearEditor();await refresh()}catch(e){notice(e.message,true)}
});
el("backup").addEventListener("click",async()=>{
 try{const response=await api("/api/backup");const blob=await response.blob(),url=URL.createObjectURL(blob),a=document.createElement("a");
 a.href=url;a.download="nostos-backup.sqlite3";document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
 notice("NOSTOS database backup downloaded.")}catch(e){notice(e.message,true)}
});
el("restore").addEventListener("submit",async event=>{
 event.preventDefault();const f=event.currentTarget;
 if(f.elements.namedItem("confirmation").value!=="RESTORE NOSTOS"){notice("The confirmation phrase does not match.",true);return}
 if(!confirm("Replace local household records with the selected backup?"))return;
 const blob=f.elements.namedItem("backup").files[0];
 try{const response=await api("/api/restore",{method:"POST",headers:{"X-NOSTOS-Restore-Confirm":"RESTORE NOSTOS","Content-Type":"application/vnd.sqlite3"},body:blob});
 const result=await response.json();f.reset();await refresh();notice("Restore completed: "+result.records+" records.")}
 catch(e){notice(e.message,true)}
});
locked();