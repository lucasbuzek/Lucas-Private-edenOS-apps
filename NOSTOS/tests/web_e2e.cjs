/* NOSTOS automated interactive browser acceptance on isolated test data.
 * Node + Playwright Chromium. Does not contact external app or real household.
 */
const {chromium} = require('playwright');
const {spawn} = require('node:child_process');
const {mkdtempSync,rmSync} = require('node:fs');
const {tmpdir} = require('node:os');
const {join,resolve} = require('node:path');
const {randomBytes} = require('node:crypto');

const port=18787;
const base='http://127.0.0.1:'+port;
const token='test-owner-'+randomBytes(32).toString('hex');
const dataDir=mkdtempSync(join(tmpdir(),'nostos-browser-test-'));
const appDir=resolve(__dirname,'..');
const env={...process.env,NOSTOS_OWNER_TOKEN:token,NOSTOS_DATA_DIR:dataDir,NOSTOS_PORT:String(port),NOSTOS_HOST:'127.0.0.1'};
let proc,browser;

async function waitForServer(){
  for(let i=0;i<100;i++){
    if(proc.exitCode!==null)throw new Error('NOSTOS server exited before browser test started');
    try{const res=await fetch(base+'/index.html');if(res.status===200)return;}catch{}
    await new Promise(r=>setTimeout(r,80));
  }
  throw new Error('NOSTOS local server startup timed out');
}
function fail(message){throw new Error(message);}
async function expectText(locator,expected){
 const actual=(await locator.textContent())||'';
 if(!actual.includes(expected))fail('Expected '+JSON.stringify(expected)+' in '+JSON.stringify(actual));
}
(async()=>{
  try{
    proc=spawn('python',['nostos.py'],{cwd:appDir,env,stdio:['ignore','pipe','pipe']});
    await waitForServer();
    browser=await chromium.launch({headless:true});
    const page=await browser.newPage({viewport:{width:390,height:844}});
    const errors=[];
    page.on('pageerror',e=>errors.push(e.message));
    await page.goto(base,{waitUntil:'networkidle'});
    await page.locator('#login input[name="token"]').fill(token);
    await page.getByRole('button',{name:'Unlock household'}).click();
    await page.locator('#work').waitFor({state:'visible'});
    await expectText(page.locator('#notice'),'household record(s) loaded');
    await page.locator('#editor select[name="kind"]').selectOption('supplies');
    await page.locator('#editor input[name="title"]').fill('Fresh oats');
    await page.locator('#editor input[name="quantity"]').fill('3');
    await page.locator('#editor input[name="due_date"]').fill('2026-11-20');
    await page.locator('#editor textarea[name="details"]').fill('Kitchen shelf');
    await page.getByRole('button',{name:'Save record'}).click();
    await expectText(page.locator('#items'),'Fresh oats');
    const card=page.locator('#items article').filter({hasText:'Fresh oats'});
    await card.getByRole('button',{name:'Edit'}).click();
    await page.locator('#editor input[name="title"]').fill('Rolled oats');
    await page.getByRole('button',{name:'Save record'}).click();
    await expectText(page.locator('#items'),'Rolled oats');
    await page.locator('#search').fill('Rolled');
    await page.locator('#search').press('Enter');
    await expectText(page.locator('#items'),'Rolled oats');
    await page.locator('#search').fill('');
    await page.locator('#search').press('Enter');
    await page.locator('#filter').selectOption('supplies');
    await expectText(page.locator('#items'),'Rolled oats');
    const downloadPromise=page.waitForEvent('download');
    await page.getByRole('button',{name:'Download backup'}).click();
    const download=await downloadPromise;
    if(download.suggestedFilename()!=='nostos-backup.sqlite3')fail('Wrong backup name');
    page.once('dialog',dialog=>dialog.accept());
    await page.locator('#items article').filter({hasText:'Rolled oats'}).getByRole('button',{name:'Delete'}).click();
    await page.locator('#items article').filter({hasText:'Rolled oats'}).waitFor({state:'detached'});
    await page.getByRole('button',{name:'Lock',exact:true}).click();
    await page.locator('#locked').waitFor({state:'visible'});
    if(errors.length)fail('Browser page errors: '+errors.join('; '));
    await page.close();
    console.log('NOSTOS browser PASS: mobile login, CRUD, filter/search, SQLite download, delete confirmation, lock, no page errors');
  }finally{
    if(browser)await browser.close();
    if(proc){proc.kill('SIGTERM');await new Promise(r=>{if(proc.exitCode!==null)r();else{proc.once('exit',r);setTimeout(r,1000)}})}
    rmSync(dataDir,{recursive:true,force:true});
  }
})().catch(e=>{console.error(e.stack||e);process.exitCode=1});
