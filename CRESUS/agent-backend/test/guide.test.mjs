import{test}from'node:test';
import assert from'node:assert/strict';
import{readFileSync}from'node:fs';
test('browser setup handles no card credentials, no auto buying or fabricated KYC verification',()=>{
 const html=readFileSync(new URL('../../PWA/public/account-setup.html',import.meta.url),'utf8');
 const js=readFileSync(new URL('../../PWA/public/account-setup.js',import.meta.url),'utf8');
 assert.match(html,/\$5 USD/);
 assert.match(html,/provider/);
 assert.match(html,/CRESUS does not create financial accounts/);
 assert.match(js,/SELF|self-reported|UNVERIFIED/i);
 assert.doesNotMatch(html,/<input[^>]+(cvv|cardNumber|password)/i);
 assert.doesNotMatch(js,/\/api\/orders|fetch\(['"]https:\/\/api\.luno\.com\/api\/1\/postorder/i);
});
