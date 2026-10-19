import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {DatabaseSync} from 'node:sqlite';
import {createD1ReleaseControls} from '../software-sharing/release-controls.mjs';

const accepted=[{
  appId:'hermes',releaseId:'v01',filename:'HERMES-v0.1.zip',
  sha256:'a'.repeat(64),sizeBytes:1000,
  approvedForSharing:true,physicalAcceptance:true,
  source:{kind:'github-release',repository:'lucasbuzek/Lucas-Private-edenOS-apps',assetId:741001},
}];
const dbFactory=()=>{
  const db=new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../software-sharing/email-tickets.sql',import.meta.url),'utf8'));
  return {db,adapter:{
    prepare(sql){
      const stmt=db.prepare(sql);
      return {bind(...args){
        return {first:async()=>stmt.get(...args)||null,
          run:async()=>{const result=stmt.run(...args);return {meta:{changes:Number(result.changes)}};}};
      }};
    },
  }};
};

test('owner release controls default to disabled even for accepted verified manifest',async()=>{
  const f=dbFactory();
  try{
    const gate=createD1ReleaseControls({db:f.adapter,releases:accepted});
    assert.equal(await gate.isEnabled('hermes','v01'),false);
    assert.deepEqual((await gate.list()).map(x=>x.enabled),[false]);
    assert.equal(await gate.isEnabled('cresus','v01'),false);
  }finally{f.db.close();}
});
test('owner may enable/disable accepted release but cannot add or modify source',async()=>{
  const f=dbFactory();
  try{
    const gate=createD1ReleaseControls({db:f.adapter,releases:accepted});
    assert.equal(await gate.setEnabled({
      appId:'hermes',releaseId:'v01',enabled:true,
      reviewer:'owner@example.com',at:100,
    }),true);
    assert.equal(await gate.isEnabled('hermes','v01'),true);
    assert.equal(await gate.setEnabled({
      appId:'cresus',releaseId:'v01',enabled:true,
      reviewer:'owner@example.com',at:100,
    }),false);
    assert.equal(await gate.setEnabled({
      appId:'hermes',releaseId:'v01',enabled:false,
      reviewer:'owner@example.com',at:200,
    }),true);
    assert.equal(await gate.isEnabled('hermes','v01'),false);
  }finally{f.db.close();}
});
test('missing accepted release manifests cannot create download entitlements',()=>{
  const f=dbFactory();
  try{
    assert.throws(()=>createD1ReleaseControls({db:f.adapter,releases:[{
      ...accepted[0],physicalAcceptance:false,
    }]}),/accepted immutable/);
  }finally{f.db.close();}
});
