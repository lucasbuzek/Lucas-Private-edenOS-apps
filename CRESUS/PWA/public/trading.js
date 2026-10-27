const el=(id)=>document.getElementById(id);
let approvedDraft=null;
const api=async (path,body) => {
 const r=await fetch(path,{method:body?'POST':'GET',credentials:'same-origin',
  headers:{'content-type':'application/json'},body:body?JSON.stringify(body):undefined});
 const data=await r.json().catch(()=>({error:'Non-JSON server response'}));
 if(!r.ok)throw Error(data.error||'Request failed ('+r.status+')');
 return data;
};
el('tradeForm').addEventListener('submit',async e=>{
 e.preventDefault();approvedDraft=null;el('recordPaper').disabled=true;
 const f=new FormData(e.currentTarget);
 const order={mic:f.get('mic'),ticker:f.get('ticker'),currency:f.get('currency'),side:'BUY',
  quantity:Number(f.get('quantity')),limitPrice:Number(f.get('limitPrice')),
  availableCapital:Number(f.get('availableCapital')),maxAllocationPercent:Number(f.get('maxAllocationPercent')),
  sourceUrl:f.get('sourceUrl')||null, observedAt:new Date().toISOString()};
 try {
  const {draft}=await api('/api/trading/preview',order);approvedDraft=order;
  el('previewOut').textContent=JSON.stringify(draft,null,2);
  el('recordPaper').disabled=false;
 }catch(err){el('previewOut').textContent=err.message;}
});
el('recordPaper').addEventListener('click',async()=>{
 if(!approvedDraft)return;el('recordPaper').disabled=true;
 try {
  const result=await api('/api/trading/paper',{
   order:approvedDraft,idempotencyKey:crypto.randomUUID(),confirm:'PAPER_ONLY'});
  el('recordOut').textContent='Recorded paper intent '+result.id+'; NOT FILLED. No live trade.';
 }catch(err){el('recordOut').textContent=err.message;}
});
el('ruleForm').addEventListener('submit',async e=>{
 e.preventDefault();const f=new FormData(e.currentTarget);
 try {
  const r=await api('/api/trading/automation/check',{
   rule:{condition:f.get('condition'),threshold:Number(f.get('threshold'))},
   quote:{price:Number(f.get('price')),verified:false,observedAt:new Date().toISOString()}});
  el('ruleOut').textContent=JSON.stringify(r,null,2);
 }catch(err){el('ruleOut').textContent=err.message;}
});
el('loadOrders').addEventListener('click',async()=>{
 try{el('ordersOut').textContent=JSON.stringify(await api('/api/trading/paper'),null,2);}
 catch(err){el('ordersOut').textContent=err.message+' (staging migration may not be applied)';}
});
