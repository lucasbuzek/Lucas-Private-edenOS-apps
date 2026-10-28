const $=id=>document.getElementById(id);
const DATA={
  easyequities:{
    title:'EasyEquities — shares / ETFs',
    details:'South African share and fractional-share investing. Card funding is documented. Official order-writing API access is NOT verified, so CRESUS can guide and record a manual test, not place this trade for you.',
    create:'https://www.easyequities.co.za/',
    support:'https://support.easyequities.co.za/support/solutions/articles/13000112049-how-do-i-deposit-money-into-my-zar-account-'
  },
  luno:{
    title:'Luno — spot cryptocurrency',
    details:'The official Luno trading API exists but CRESUS has no trading key and live orders are disabled. Official help articles conflict about current instant-card availability; confirm in your verified account before trying a virtual card. Crypto is a separate test scope from equity investing.',
    create:'https://www.luno.com/',
    support:'https://guide.luno.com/hc/en-gb/articles/11035573761181-I-m-a-foreign-resident-not-a-local-citizen-Can-I-still-open-a-Luno-account'
  }
};
const STEPS=[
  ['Choose the provider and open its official website','Do not enter a broker password into CRESUS.'],
  ['Create account using the provider website','Verify the email address and phone with the provider itself.'],
  ['Complete identity and residency verification','Upload documents only to the official provider.'],
  ['Confirm the virtual card is actually accepted','Check card issuer, 3-D Secure, currency and provider restrictions.'],
  ['Inspect all fees, FX and minimum transaction sizes','Total funding AND transaction fees must stay within the $5 limit.'],
  ['Fund manually through the authenticated provider','CRESUS will not request or store card numbers or payment codes.'],
  ['Confirm funds/holdings from the provider receipt','Self-reported status is not an API-verified account balance.'],
  ['Review proposed trade and manually authorize','No unattended order execution in this proof.']
];
const safeGet=(k,d)=>{try{return JSON.parse(localStorage.getItem(k))??d;}catch{return d;}};
const safeSet=(k,v)=>{try{localStorage.setItem(k,JSON.stringify(v));}catch{}};
let provider=safeGet('cresus.first5.provider','easyequities');
if(!DATA[provider])provider='easyequities';
let complete=safeGet('cresus.first5.steps.'+provider,[]);
if(!Array.isArray(complete))complete=[];
function show(){
 const d=DATA[provider];$('providerHeading').textContent=d.title;
 $('providerDetails').textContent=d.details;$('createLink').href=d.create;$('supportLink').href=d.support;
 document.querySelectorAll('[name=provider]').forEach(x=>x.checked=x.value===provider);
 $('steps').replaceChildren();
 STEPS.forEach(([title,note],i)=>{
   const label=document.createElement('label'),check=document.createElement('input');
   check.type='checkbox';check.checked=complete.includes(i);check.addEventListener('change',()=>{
      complete=check.checked?[...new Set([...complete,i])]:complete.filter(n=>n!==i);
      safeSet('cresus.first5.steps.'+provider,complete);update();
   });
   const span=document.createElement('span');span.textContent=' '+title+' — '+note;
   label.append(check,span);$('steps').appendChild(label);
 });
 update();
}
function update(){$('progress').textContent=complete.length+' / '+STEPS.length+
 ' self-reported steps; account, deposit and live-trade status remain UNVERIFIED.';}
document.querySelectorAll('[name=provider]').forEach(input=>input.addEventListener('change',()=>{
 provider=input.value;safeSet('cresus.first5.provider',provider);
 complete=safeGet('cresus.first5.steps.'+provider,[]);if(!Array.isArray(complete))complete=[];show();
}));
$('reset').addEventListener('click',()=>{complete=[];safeSet('cresus.first5.steps.'+provider,[]);show();});
show();
