import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {DatabaseSync} from 'node:sqlite';
import {createEmailDownloadService,createCloudflareEmailMailer,
  validateEmailLinkReleases} from '../software-sharing/email-links.mjs';
import {createD1EmailTicketStore} from '../software-sharing/email-tickets.mjs';

const bytes=new TextEncoder().encode('A verified private test artifact.');
const sha=createHash('sha256').update(bytes).digest('hex');
const release={
  appId:'hermes',releaseId:'v01',filename:'HERMES-v0.1.zip',
  sizeBytes:bytes.length,sha256:sha,approvedForSharing:true,physicalAcceptance:true,
  source:{kind:'github-release',repository:'lucasbuzek/Lucas-Private-edenOS-apps',assetId:741001},
};
const origin='https://edenosportal.pages.dev/';
const owner={id:'verified-owner',email:'owner@example.com',allowedApps:['lucas-admin']};
const req=(token)=>new Request(origin+'api/software-sharing/redeem',{
  method:'POST',headers:{origin:origin.slice(0,-1),
    'content-type':'application/x-www-form-urlencoded'},
  body:new URLSearchParams({ticket:token}).toString(),
});
function fixture({active=true,releaseActive=true,mailWorks=true,artifactValid=true,clockStart=1000000}={}) {
  const db=new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../software-sharing/email-tickets.sql',import.meta.url),'utf8'));
  let now=clockStart,emails=[],reads=0;
  const d1={
    prepare(sql){
      const stmt=db.prepare(sql);
      const wrap=(args)=>({
        async first(){return stmt.get(...args)||null;},
        async run(){const r=stmt.run(...args);return {meta:{changes:Number(r.changes)}};},
        async all(){return {results:stmt.all(...args)};},
      });
      return {bind(...args){return wrap(args)},...wrap([])};
    },
    async batch(statements) {
      db.exec('BEGIN IMMEDIATE');
      try{for(const statement of statements)await statement.run();db.exec('COMMIT');}
      catch(e){db.exec('ROLLBACK');throw e;}
    },
  };
  const tickets=createD1EmailTicketStore(d1);
  const service=createEmailDownloadService({
    releases:[release],origin,ownerEmail:'owner@example.com',tickets,
    approved:async(app,email)=>active&&app==='hermes'&&email==='approved@example.com',
    releaseEnabled:async(app,id)=>releaseActive&&app==='hermes'&&id==='v01',
    sendEmail:async mail=>{if(!mailWorks)throw Error('mail unavailable');emails.push(mail);return {submitted:true};},
    readArtifact:async()=>{reads++;return artifactValid?bytes:new TextEncoder().encode('bad');},
    now:()=>now,
  });
  return {db,service,tickets,get emails(){return emails},get reads(){return reads},
    tick:ms=>{now+=ms},stopApproval:()=>{active=false},disableRelease:()=>{releaseActive=false}};
}

test('empty accepted registry is safe, no email link may be issued',async()=>{
  assert.deepEqual(validateEmailLinkReleases([]),{ok:true,errors:[]});
  const f=fixture();
  try{
    const unauthorized=await f.service.issue({principal:owner,email:'approved@example.com',
      appId:'cresus',releaseId:'v01'});
    assert.equal(unauthorized.state,'UNAVAILABLE');
    assert.equal(f.emails.length,0);
  }finally{f.db.close();}
});

test('owner-approved recipient receives email-fragment link but no raw token in API result',async()=>{
  const f=fixture();
  try{
    const result=await f.service.issue({principal:owner,email:'approved@example.com',
      appId:'hermes',releaseId:'v01'});
    assert.equal(result.state,'SUBMITTED');
    assert.equal(f.emails.length,1);
    assert.match(f.emails[0].link,/^https:\/\/edenosportal\.pages\.dev\/download\/redeem#ticket=/);
    assert.doesNotMatch(JSON.stringify(result),/ticket=/);
    const url=new URL(f.emails[0].link);
    assert.equal(url.search,'');
    assert.equal(url.pathname,'/download/redeem');
    assert.equal(url.hash.split('=')[1].length,43);
    const landing=await f.service.fetch(new Request(origin+'download/redeem'));
    assert.equal(landing.status,200);
    assert.match(await landing.text(),/disabled type="submit"/);
    assert.equal(f.reads,0);
    const script=await f.service.fetch(new Request(origin+'download/redeem.js'));
    assert.match(await script.text(),/history\.replaceState/);
  }finally{f.db.close();}
});

test('one-time email link downloads exactly verified bytes, then rejects replay',async()=>{
  const f=fixture();
  try{
    await f.service.issue({principal:owner,email:'approved@example.com',
      appId:'hermes',releaseId:'v01'});
    const token=new URL(f.emails[0].link).hash.split('=')[1];
    const first=await f.service.fetch(req(token));
    assert.equal(first.status,200);
    assert.deepEqual(new Uint8Array(await first.arrayBuffer()),bytes);
    assert.match(first.headers.get('content-disposition'),/HERMES-v0.1.zip/);
    assert.equal(first.headers.get('cache-control'),'no-store');
    assert.equal((await f.service.fetch(req(token))).status,403);
    assert.equal(f.reads,1);
  }finally{f.db.close();}
});

test('expired, denied, unapproved and forged owner links fail closed',async()=>{
  const f=fixture();
  try{
    for(const principal of [null,{id:'x',email:'attacker@example.com',allowedApps:['lucas-admin']},
       {id:'x',email:'owner@example.com',allowedApps:[]}]){
      const result=await f.service.issue({principal,email:'approved@example.com',
        appId:'hermes',releaseId:'v01'});
      assert.equal(result.state,'DENIED');
    }
    assert.equal((await f.service.issue({principal:owner,email:'unapproved@example.com',
      appId:'hermes',releaseId:'v01'})).state,'DENIED');
    await f.service.issue({principal:owner,email:'approved@example.com',
      appId:'hermes',releaseId:'v01'});
    const token=new URL(f.emails[0].link).hash.split('=')[1];
    f.stopApproval();
    assert.equal((await f.service.fetch(req(token))).status,403);
    assert.equal(f.reads,0);
  }finally{f.db.close();}
  const exp=fixture();
  try{
    await exp.service.issue({principal:owner,email:'approved@example.com',
      appId:'hermes',releaseId:'v01'});
    const token=new URL(exp.emails[0].link).hash.split('=')[1];
    exp.tick(16*60*1000);
    assert.equal((await exp.service.fetch(req(token))).status,403);
  }finally{exp.db.close();}
});

test('email submission failure revokes ticket; verified file checksum failure never returns bytes',async()=>{
  const fail=fixture({mailWorks:false});
  try{
    assert.equal((await fail.service.issue({principal:owner,email:'approved@example.com',
      appId:'hermes',releaseId:'v01'})).state,'UNAVAILABLE');
    assert.equal(fail.emails.length,0);
  }finally{fail.db.close();}
  const corrupt=fixture({artifactValid:false});
  try{
    await corrupt.service.issue({principal:owner,email:'approved@example.com',
      appId:'hermes',releaseId:'v01'});
    const token=new URL(corrupt.emails[0].link).hash.split('=')[1];
    assert.equal((await corrupt.service.fetch(req(token))).status,503);
  }finally{corrupt.db.close();}
});

test('cross-site POST and invalid tokens cannot trigger private artifact access',async()=>{
  const f=fixture();
  try{
    await f.service.issue({principal:owner,email:'approved@example.com',
      appId:'hermes',releaseId:'v01'});
    const token=new URL(f.emails[0].link).hash.split('=')[1];
    const wrong=new Request(origin+'api/software-sharing/redeem',{
      method:'POST',headers:{origin:'https://attacker.example',
        'content-type':'application/x-www-form-urlencoded'},
      body:new URLSearchParams({ticket:token}).toString(),
    });
    assert.equal((await f.service.fetch(wrong)).status,403);
    assert.equal((await f.service.fetch(req('bad'))).status,400);
    assert.equal(f.reads,0);
  }finally{f.db.close();}
});

test('Cloudflare mailer uses verified sender, narrow recipient and provider accepted message id',async()=>{
  let captured;
  const mail=createCloudflareEmailMailer({
    binding:{send:async x=>{captured=x;return {messageId:'test-email-id'}}},
    from:'noreply@owned.example',
  });
  const result=await mail({to:'approved@example.com',
    link:origin+'download/redeem#ticket='+('A'.repeat(43)),appId:'hermes',
    filename:'HERMES-v0.1.zip'});
  assert.equal(result.submitted,true);
  assert.equal(captured.to,'approved@example.com');
  assert.equal(captured.from,'noreply@owned.example');
  assert.match(captured.text,/15 minutes/);
});


test('owner disabling an accepted release blocks issuance and immediately invalidates a pending link',async()=>{
  const f=fixture();
  try{
    assert.equal((await f.service.issue({
      principal:owner,email:'approved@example.com',appId:'hermes',releaseId:'v01'
    })).state,'SUBMITTED');
    const token=new URL(f.emails[0].link).hash.split('=')[1];
    f.disableRelease();
    assert.equal((await f.service.fetch(req(token))).status,403);
    assert.equal((await f.service.issue({
      principal:owner,email:'approved@example.com',appId:'hermes',releaseId:'v01'
    })).reason,'RELEASE_DISABLED_BY_OWNER');
    assert.equal(f.reads,0);
  }finally{f.db.close();}
});
