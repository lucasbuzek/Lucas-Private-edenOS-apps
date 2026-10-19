import test from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import {createD1SharingRateLimit} from '../software-sharing/rate-limit.mjs';
import {d1WaitlistStore} from '../closed-testing/d1.mjs';

const hash=letter=>letter.repeat(64);
function dbFixture(){
  const db=new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('../software-sharing/schema.sql',import.meta.url),'utf8'));
  const d1={prepare(sql){
    const stmt=db.prepare(sql);
    return {
      bind(...args){return {
        async run(){const result=stmt.run(...args);return {meta:{changes:Number(result.changes)}};},
        async first(){return stmt.get(...args)||null;},
        async all(){return {results:stmt.all(...args)};},
      }},
    };
  }};
  return {db,d1};
}

test('private sharing queue retains app-specific pending/approved/denied status in durable SQL',async()=>{
  const {db,d1}=dbFixture(),store=d1WaitlistStore(d1);
  try{
    assert.equal(await store.request('hermes','member@example.com'),true);
    assert.equal(await store.request('hermes','member@example.com'),false);
    assert.equal(await store.request('cresus','member@example.com'),true);
    assert.equal(await store.isApproved('hermes','member@example.com'),false);
    await store.decide('hermes','member@example.com','approve','owner@example.com');
    assert.equal(await store.isApproved('hermes','member@example.com'),true);
    assert.equal(await store.isApproved('cresus','member@example.com'),false);
    await store.decide('hermes','member@example.com','deny','owner@example.com');
    assert.equal(await store.isApproved('hermes','member@example.com'),false);
  }finally{db.close();}
});

test('atomic D1 rate limiting independently restricts hashed source and email',async()=>{
  const {db,d1}=dbFixture();
  try{
    let time=Date.UTC(2026,9,19,10);
    const allow=createD1SharingRateLimit({db:d1,clock:()=>time,ipHourlyLimit:2,emailDailyLimit:1});
    const ip='share:source:'+hash('a');
    const email='share:email:'+hash('b');
    assert.equal(await allow(ip),true);
    assert.equal(await allow(ip),true);
    assert.equal(await allow(ip),false);
    assert.equal(await allow(email),true);
    assert.equal(await allow(email),false);
    assert.equal(await allow('share:source:raw-personal-address'),false);
    time+=3600_000;
    assert.equal(await allow(ip),true);
    assert.equal(await allow(email),false);
    time+=86400_000;
    assert.equal(await allow(email),true);
  }finally{db.close();}
});
