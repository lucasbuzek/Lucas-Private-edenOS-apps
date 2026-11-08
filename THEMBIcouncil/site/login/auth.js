'use strict';
(()=>{
 const by=id=>document.getElementById(id),note=by('state'),g=by('google'),a=by('apple');
 const status=(txt,bad=false)=>{note.textContent=txt;note.classList.toggle('error',bad)};
 const encode=bytes=>btoa(String.fromCharCode(...bytes)).replace(/\+/g,'-').replace(/\//g,'_').replace(/=/g,'');
 const validNext=v=>typeof v==='string'&&v.startsWith('/app/')&&!v.startsWith('//')&&!v.includes('\\')?v:'/app/';
 const requested=new URL(location.href);
 const next=validNext(requested.searchParams.get('next')||sessionStorage.getItem('tc_next')||'/app/');
 sessionStorage.setItem('tc_next',next);
 async function configuration(){
  const r=await fetch('/login/config',{credentials:'same-origin',headers:{Accept:'application/json'}});
  if(!r.ok)throw Error('Cannot retrieve the Council sign-in configuration.');
  return r.json();
 }
 async function begin(provider,cfg){
  g.disabled=true;a.disabled=true;status('Opening '+(provider==='google'?'Google':'Apple')+' sign-in…');
  const verifier=encode(crypto.getRandomValues(new Uint8Array(32)));
  const digest=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(verifier));
  sessionStorage.setItem('tc_pkce_verifier',verifier);
  const url=new URL('/auth/v1/authorize',cfg.url);
  url.searchParams.set('provider',provider);
  url.searchParams.set('redirect_to',location.origin+'/login/');
  url.searchParams.set('flow_type','pkce');
  url.searchParams.set('code_challenge',encode(new Uint8Array(digest)));
  url.searchParams.set('code_challenge_method','s256');
  location.assign(url.href);
 }
 async function finish(code){
  const verifier=sessionStorage.getItem('tc_pkce_verifier')||'';
  history.replaceState(null,'','/login/');
  if(!verifier){status('Your sign-in session expired. Start again.',true);return}
  sessionStorage.removeItem('tc_pkce_verifier');
  status('Securing your personal session…');
  const r=await fetch('/login/exchange',{method:'POST',credentials:'same-origin',headers:{'Content-Type':'application/json',Accept:'application/json'},body:JSON.stringify({code,code_verifier:verifier})});
  const data=await r.json().catch(()=>({error:'invalid_login_response'}));
  if(!r.ok)throw Error(data.error||'Unable to complete sign-in.');
  sessionStorage.removeItem('tc_next');
  location.replace(next);
 }
 (async()=>{
  try{
   const error=requested.searchParams.get('error_description')||requested.searchParams.get('error');
   if(error){status('Sign-in was not completed. You can try again.',true);history.replaceState(null,'','/login/');return}
   const cfg=await configuration();
   if(!cfg.ready||!/^https:\/\/[a-z0-9-]+\.supabase\.co$/.test(cfg.url||'')){status('Account sign-in is not yet activated. Please contact the Council administrator.',true);return}
   const code=requested.searchParams.get('code');
   if(code){await finish(code);return}
   g.disabled=false;a.disabled=false;status('Choose Google or Apple to sign in to your personal Council.');
   g.addEventListener('click',()=>begin('google',cfg).catch(()=>status('Google sign-in could not open.',true)));
   a.addEventListener('click',()=>begin('apple',cfg).catch(()=>status('Apple sign-in could not open.',true)));
  }catch(e){status(e.message||'Sign-in could not be started.',true)}
 })();
})();
