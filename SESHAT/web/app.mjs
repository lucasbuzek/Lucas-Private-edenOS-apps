import { createLedgerState, getStockSummary, postMovement } from "./src/domain/ledger.mjs";
import { searchProducts } from "./src/domain/queries.mjs";
import { addProduct, addLocation, validateCatalogue } from "./src/domain/catalogue.mjs";
import { exportLedgerSnapshot, importLedgerSnapshot } from "./src/persistence/snapshot.mjs";
import { openInventoryDB, readInventory, saveInventory } from "./src/persistence/browser-idb.mjs";
import { demoCatalogue, demoLedgerState, demoProvenance } from "./fixtures/demo-inventory.mjs";

const $ = id => document.getElementById(id);
const num = n => new Intl.NumberFormat("en-ZA", { maximumFractionDigits: 3 }).format(n);
const required = () => crypto.randomUUID();
let db, ledger = createLedgerState(), catalogue = [], revision = 0, provenance = "local", savedAt = null, pending = null;
function message(text, error = false) {
  const el = $("notice"); el.hidden = false; el.textContent = text; el.classList.toggle("error", error);
}
function fail(err) { message(err?.message || String(err), true); pending = null; $("post-movement").disabled = true; }
function cellrow(target, cells, status = "") {
  const tr = document.createElement("tr");
  for (const v of cells) { const td = document.createElement("td"); td.textContent = String(v ?? "—"); tr.append(td); }
  if (status) tr.lastElementChild.className = status;
  target.append(tr);
}
function options(el, pairs) {
  const previous = el.value; el.replaceChildren();
  for (const [value, label] of pairs) { const op = document.createElement("option"); op.value = value; op.textContent = label; el.add(op); }
  if (pairs.some(x => x[0] === previous)) el.value = previous;
}
function invalidPreview() {
  pending = null; $("post-movement").disabled = true;
  $("movement-preview").textContent = "Nothing to post. Select a product, location and quantity.";
}
async function commit(nextLedger, nextCatalogue, nextOrigin = provenance) {
  validateCatalogue(nextCatalogue, nextLedger);
  const snapshot = await exportLedgerSnapshot(nextLedger);
  const newRevision = await saveInventory(db, { snapshot, catalogue: nextCatalogue, provenance: nextOrigin }, revision);
  ledger = nextLedger; catalogue = nextCatalogue; provenance = nextOrigin; revision = newRevision; savedAt = new Date().toISOString();
  invalidPreview(); render();
}
function renderOverview() {
  $("stat-products").textContent = catalogue.length;
  $("stat-locations").textContent = ledger.locations.length;
  $("stat-movements").textContent = ledger.events.length;
  const results = $("filter-products").value ? searchProducts(catalogue, $("filter-products").value) : catalogue;
  $("overview-body").replaceChildren();
  let low = 0;
  for (const p of catalogue) {
    const q = getStockSummary(ledger,p.id).total;
    if (p.reorderPoint != null && q <= p.reorderPoint) low++;
  }
  $("stat-low").textContent = low;
  for (const p of results) {
    const q = getStockSummary(ledger,p.id).total;
    const isLow = p.reorderPoint != null && q <= p.reorderPoint;
    cellrow($("overview-body"),[p.name,p.id,num(q)+" "+p.unit,p.reorderPoint == null ? "Not set" : num(p.reorderPoint),p.reorderPoint == null ? "Unknown" : isLow ? "Low stock" : "In stock"],p.reorderPoint == null ? "" : isLow ? "status-low" : "status-ok");
  }
  if (!results.length) cellrow($("overview-body"),["No matching products","","","",""]);
}
function render() {
  renderOverview();
  $("location-list").replaceChildren();
  for (const loc of ledger.locations) { const li = document.createElement("li"); li.textContent = loc; $("location-list").append(li); }
  options($("movement-product"),catalogue.map(p => [p.id,p.name+" ("+p.id+")"]));
  options($("movement-location"),ledger.locations.map(id => [id,id]));
  options($("movement-to"),ledger.locations.map(id => [id,id]));
  $("history-body").replaceChildren();
  for (const e of ledger.events.slice().reverse().slice(0,100)) {
    cellrow($("history-body"),[new Date(e.occurredAt).toLocaleString(),e.type,e.productId,num(e.quantity)+" "+e.unit,e.type==="transfer"?e.fromLocationId+" → "+e.toLocationId:e.locationId,e.reference||"—"]);
  }
  $("history-count").textContent = ledger.events.length+" ledger entries (latest 100 displayed)";
  $("source-status").textContent = (provenance==="fixture"?"DEMONSTRATION DATA — not live stock":"Local records")+" · revision "+revision;
  $("storage-status").textContent = "IndexedDB profile revision "+revision+". "+(savedAt?"Saved "+new Date(savedAt).toLocaleString():"Not yet saved")+". No remote backup, sync or multi-user authorization.";
}
function switchView(view) {
  document.querySelectorAll("[data-panel]").forEach(el => { el.hidden = el.dataset.panel !== view; });
  document.querySelectorAll("[data-page]").forEach(el => { el.classList.toggle("active",el.dataset.page===view); el.setAttribute("aria-current",el.dataset.page===view?"page":"false"); });
}
function movementInput(form) {
  const d = new FormData(form), productId=d.get("productId"), product=ledger.products[productId];
  if (!product) throw new Error("Choose a product.");
  const type=d.get("type"), id=required();
  const m={id,idempotencyKey:id,type,productId,unit:product.unit,quantity:Number(d.get("quantity")),occurredAt:new Date().toISOString(),reference:String(d.get("reference")||"").trim()||null};
  if(type==="transfer"){m.fromLocationId=d.get("locationId");m.toLocationId=d.get("toLocationId");}
  else m.locationId=d.get("locationId");
  return m;
}
document.querySelectorAll("[data-page]").forEach(el=>el.addEventListener("click",()=>switchView(el.dataset.page)));
$("filter-products").addEventListener("input",renderOverview);
$("movement-type").addEventListener("change",()=>{
  $("to-location-label").hidden=$("movement-type").value!=="transfer";
  invalidPreview();
});
$("movement-form").addEventListener("input",invalidPreview);
$("movement-form").addEventListener("change",invalidPreview);
$("product-form").addEventListener("submit",async ev=>{
  ev.preventDefault();
  try {
    const d=new FormData(ev.currentTarget), next=addProduct(ledger,catalogue,{id:d.get("sku"),name:d.get("name"),unit:d.get("unit"),barcode:d.get("barcode"),category:d.get("category"),reorderPoint:d.get("reorder")});
    await commit(next.ledger,next.catalogue); ev.currentTarget.reset(); message("Product saved to local catalogue.");
  } catch(err){fail(err);}
});
$("location-form").addEventListener("submit",async ev=>{
  ev.preventDefault();
  try {const next=addLocation(ledger,catalogue,new FormData(ev.currentTarget).get("location"));await commit(next.ledger,next.catalogue);ev.currentTarget.reset();message("Location saved.");}
  catch(err){fail(err);}
});
$("movement-form").addEventListener("submit",ev=>{
  ev.preventDefault();
  try {
    const m=movementInput(ev.currentTarget);
    const result=postMovement(ledger,m);
    pending={movement:m,revision,nextLedger:result.state};
    $("movement-preview").textContent="PREVIEW ONLY: "+m.type+" "+num(m.quantity)+" "+m.unit+" of "+m.productId+" at "+(m.fromLocationId||m.locationId)+(m.toLocationId?" → "+m.toLocationId:"")+". Confirm to post locally.";
    $("post-movement").disabled=false;
  }catch(err){fail(err);}
});
$("post-movement").addEventListener("click",async ()=>{
  if(!pending||pending.revision!==revision){fail(new Error("Preview is stale. Preview again."));return;}
  const m=pending.movement;$("post-movement").disabled=true;
  try{const result=postMovement(ledger,m);await commit(result.state,catalogue);$("movement-form").reset();$("to-location-label").hidden=true;message("Append-only movement posted locally.");}
  catch(err){fail(err);}
});
$("export-button").addEventListener("click",async ()=>{
  try{
    const snapshot=await exportLedgerSnapshot(ledger);
    const content=JSON.stringify({format:"seshat-portable-v1",exportedAt:new Date().toISOString(),catalogue,provenance,snapshot},null,2)+"\n";
    const url=URL.createObjectURL(new Blob([content],{type:"application/json"}));
    const anchor=document.createElement("a");anchor.href=url;anchor.download="SESHAT-backup-"+new Date().toISOString().slice(0,10)+".json";
    document.body.append(anchor);anchor.click();anchor.remove();setTimeout(()=>URL.revokeObjectURL(url),30000);
    message("Backup generated. Confirm an independent restore before relying on it.");
  }catch(err){fail(err);}
});
$("import-file").addEventListener("change",ev=>{$("import-button").disabled=!ev.currentTarget.files?.length;});
$("import-button").addEventListener("click",async ()=>{
  try {
    const file=$("import-file").files?.[0];
    if(!file)throw new Error("Choose a backup.");
    if(file.size>5*1024*1024)throw new Error("Backup exceeds 5 MB import limit.");
    const text=await file.text();let obj;
    try{obj=JSON.parse(text);}catch{throw new Error("Invalid backup JSON.");}
    let snapshot=text,cat;
    if(obj.format==="seshat-portable-v1"){snapshot=obj.snapshot;cat=obj.catalogue;}
    const restored=await importLedgerSnapshot(snapshot);
    if(!cat)cat=Object.values(restored.products).map(p=>({...p,barcode:"",category:"",reorderPoint:null}));
    validateCatalogue(cat,restored);
    if(!confirm("Replace all local stock data with this validated backup? Export your existing profile first."))return;
    await commit(restored,cat,"restored");message("Validated backup restored to local profile.");
  }catch(err){fail(err);}
});
function network(){ $("network-state").textContent=navigator.onLine?"Browser online":"Browser offline"; }
window.addEventListener("online",network);window.addEventListener("offline",network);
async function start(){
  switchView("overview"); network();
  try{
    db=await openInventoryDB();
    const saved=await readInventory(db);
    if(saved){
      const next=await importLedgerSnapshot(saved.snapshot);validateCatalogue(saved.catalogue,next);
      ledger=next;catalogue=saved.catalogue;revision=saved.revision;provenance=saved.provenance;savedAt=saved.savedAt;
    }
    render();
    if(revision===0){
      const b=document.createElement("button");b.type="button";b.className="primary";b.style.marginTop="20px";b.textContent="Load demonstration data";
      document.querySelector(".hero > div:first-child").append(b);
      b.addEventListener("click",async()=>{
        if(revision!==0||!confirm("Load fabricated sample inventory into this empty local profile?"))return;
        try{await commit(demoLedgerState,demoCatalogue.map(p=>({...p})),demoProvenance.kind);b.remove();message("Demonstration inventory loaded — not real business stock.");}catch(err){fail(err);}
      });
    }
    if("serviceWorker" in navigator && location.protocol!=="file:")navigator.serviceWorker.register("./sw.js").catch(err=>message("Offline shell unavailable: "+err.message,true));
  }catch(err){
    fail(err);$("source-status").textContent="Local storage unavailable";
    document.querySelectorAll("form button[type='submit'],#post-movement,#import-button").forEach(el=>{el.disabled=true;});
  }
}
start();
