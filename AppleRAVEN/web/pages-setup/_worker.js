const css = `
:root{font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color-scheme:dark;color:#eaf2fb;background:#0c121d}*{box-sizing:border-box}
body{margin:0;background:radial-gradient(ellipse at 85% 0%,#172a40 0%,transparent 50%),#0c121d}
main{width:min(1000px,calc(100% - 36px));margin:0 auto;padding:38px 0 74px}
header{display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #324054;padding-bottom:22px}
.brand{font-size:18px;font-weight:750;letter-spacing:.16em}.eyebrow{font-size:12px;color:#96bbd9;text-transform:uppercase;letter-spacing:.14em}
h1{font-size:clamp(38px,6vw,65px);letter-spacing:-.052em;line-height:1.08;max-width:810px;margin:38px 0 14px}
p{line-height:1.62;color:#bdcddd}.lead{font-size:18px;max-width:730px}
.cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px;margin:28px 0}
section{border:1px solid #2c415a;background:#172131;border-radius:18px;padding:22px}
h2{font-size:19px;margin:0 0 8px}h3{font-size:16px;margin:5px 0}.small{font-size:13px;color:#99aaba}
a{color:#badafa}a.action{display:inline-block;text-decoration:none;color:#11263a;background:#e3ecfa;border-radius:10px;padding:11px 17px;font-weight:650}
ol{margin:18px 0;padding-left:23px}li{margin:13px 0;line-height:1.55;color:#c4d0e1}
.status{color:#ffe3a6;border:1px solid #ad8755;border-radius:26px;padding:7px 12px;font-size:12px}
footer{font-size:12px;color:#91a4b9;border-top:1px solid #31415a;padding-top:22px;margin-top:32px;line-height:1.7}
@media(max-width:640px){.cards{grid-template-columns:1fr}header{align-items:flex-start;gap:16px}}
`;
const page = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>AppleRAVEN | Owner device setup</title><style>${css}</style></head><body><main>
<header><div class="brand">APPLE<span style="color:#9ec7f0">RAVEN</span></div><span class="status">Owner-only pairing pending</span></header>
<div class="eyebrow" style="margin-top:40px">Oracle VM · Cloudflare Pages · AppleRAVEN MCP · MacBook Air M1</div>
<h1>One connection. Independently controlled.</h1><p class="lead">The Oracle Ubuntu Always Free VM is a required routing tier. Cloudflare provides the web setup and owner-authenticated MCP entry point. A separately installed Mac agent performs native actions. Remote Desktop Commander is not required.</p>
<div class="cards">
<section><h2>Cloudflare owner control</h2><p>Use the existing private AppleRAVEN login and device pairing service. This setup page never accepts passwords, SSH private keys or device tokens.</p><a class="action" href="https://appleraven-private.lucasravensnest.workers.dev/pair">Open secure Mac pairing</a></section>
<section><h2>Mac installer and source</h2><p>Use the original AppleRAVEN installer candidate. A signed/notarized DMG is not yet available. This page will not serve an unverified app.</p><a class="action" href="https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/tree/candidate/appleraven-native-dmg-elysium-proof-20261028/AppleRAVEN/mac">View Mac build source</a></section>
<section><h2>Existing ChatGPT plugin</h2><p>Keep the same private AppleRAVEN plugin ID and existing Cloudflare OAuth endpoint. Real client authorization and native tool calls require separate validation.</p><a class="action" href="https://chatgpt.com/plugins/plugins_6ae05fb243a48191a7cd678e20ee608c">Open AppleRAVEN plugin</a></section>
<section><h2>ELYSIUM demonstration</h2><p>Open the existing isolated browser-local demonstration of Personal, Business and Organization task workspaces. It does not control the Mac.</p><a class="action" href="https://appleraven-onboarding.lucasravensnest.workers.dev/">Open ELYSIUM demo</a></section>
</div>
<section><h2>Required deployment architecture</h2><ol>
<li><b>Cloudflare Pages:</b> setup UI, installation guide and owner navigation. No access tokens stored.</li>
<li><b>Cloudflare AppleRAVEN:</b> existing authenticated owner MCP and device-pairing Workers.</li>
<li><b>Oracle Always Free Ubuntu VM:</b> persistent routing/management tier, keeping existing BIFROST containers intact. Reach it through an authorized private tunnel, never a public unauthenticated shell.</li>
<li><b>MacBook Air M1:</b> outbound-only, separately authorized AppleRAVEN native agent and Keychain device credential.</li>
<li><b>ChatGPT:</b> original private plugin calls only scope-approved native Apple tools and verifies revocation.</li></ol><p class="small">Oracle VM running is user-reported; AppleRAVEN Oracle routing and Mac pairing have not yet been accepted. The live AppleRAVEN database previously showed zero enrolled devices.</p></section>
<footer>Protected installation architecture. This page does not display private SSH endpoints or store credentials. No unrelated VM services are modified. Actual completion requires authenticated VM tunnel, Mac enrollment, and a genuine native result in ChatGPT.</footer>
</main></body></html>`;
export default { async fetch(request) {
  const path = new URL(request.url).pathname;
  if (path === "/health") return new Response(JSON.stringify({service:"appleraven-setup",architecture:"cloudflare-pages-oracle-vm-native-mac",mode:"setup-only",mac_pairing:"unverified",oracle_tunnel:"unverified"}), {headers:{"content-type":"application/json","cache-control":"no-store"}});
  if (path === "/" || path === "/setup") return new Response(page, {headers:{"content-type":"text/html;charset=utf-8","cache-control":"no-store","x-content-type-options":"nosniff","referrer-policy":"no-referrer","content-security-policy":"default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"}});
  return new Response("Not found",{status:404});
}};