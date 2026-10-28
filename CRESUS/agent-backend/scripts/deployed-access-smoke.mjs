// Outside-in production Access smoke, unauthenticated only.
// Never follows sign-in redirects, sends cookies, or calls order/funding routes.
import assert from 'node:assert/strict';
const origin='https://cresus-agent.lucasbuzek.workers.dev';
const paths=['/','/api/me','/api/intelligence','/api/conversations'];
const allowedAuthHosts=new Set(['floral-sky-7240.cloudflareaccess.com','cresus-agent.lucasbuzek.workers.dev']);
async function check(path, fetchFn=fetch) {
 const response=await fetchFn(origin+path,{
   method:'GET',redirect:'manual',signal:AbortSignal.timeout(15000),
   headers:{'accept':'text/html,application/json;q=0.8'}
 });
 const location=response.headers.get('location');
 let gate='UNKNOWN';
 if ([301,302,303,307,308].includes(response.status)&&location) {
   const to=new URL(location,origin);
   assert(allowedAuthHosts.has(to.hostname),'Unexpected Access redirect host');
   // Do not log query params: may contain ephemeral state.
   if(/\/cdn-cgi\/access\/|\/login|\/authorize|\/sign-in/i.test(to.pathname))
     gate='ACCESS_REDIRECT';
 }
 else if ([401,403].includes(response.status)) gate='ACCESS_DENIED';
 else if (response.status===200) {
   const body=(await response.text()).slice(0,30000);
   if(/cloudflare access|zero trust|sign in to|sign in with|access login/i.test(body)
       && !/<title>\s*CRESUS\s*<\/title>/i.test(body)) gate='ACCESS_LOGIN_PAGE';
 }
 assert.notEqual(gate,'UNKNOWN',
    'Unauthenticated '+path+' yielded an unexpected response (HTTP '+response.status+')');
 process.stdout.write(JSON.stringify({path,status:response.status,gate})+'\n');
 return {path,status:response.status,gate};
}
if(process.argv[1]&&import.meta.url===new URL('file://'+process.argv[1]).href){
 try{
  for(const path of paths) await check(path);
  process.stdout.write('CRESUS_PUBLIC_ACCESS_GATE_PASS: '+paths.length+' paths protected; authenticated UI and model NOT tested.\n');
 }catch(e){process.stderr.write('CRESUS_ACCESS_GATE_UNVERIFIED: '+String(e?.message||e)+'\n');process.exitCode=1;}
}
export {check};
