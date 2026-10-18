import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import { d1WaitlistStore } from '../closed-testing/d1.mjs';

function fixture() {
  const sqlite=new DatabaseSync(':memory:');
  sqlite.exec(readFileSync(new URL('../closed-testing/schema.sql',import.meta.url),'utf8'));
  const db={
    prepare(sql){
      const stmt=sqlite.prepare(sql);
      return {
        bind(...values) {
          return {
            async run(){const r=stmt.run(...values);return {meta:{changes:Number(r.changes)}};},
            async first(){return stmt.get(...values) || null;},
            async all(){return {results:stmt.all(...values)};},
          };
        },
      };
    },
  };
  return {sqlite,store:d1WaitlistStore(db)};
}

test('D1-compatible SQL persists pending, owner approval and denial without duplicate reinstatement',async()=>{
  const {sqlite,store}=fixture();
  try {
    await store.request('cresus','tester@example.com');
    assert.equal(await store.isApproved('cresus','tester@example.com'),false);
    assert.equal((await store.list('cresus')).length,1);
    assert.equal(await store.decide('cresus','tester@example.com','approve','owner@example.com'),true);
    assert.equal(await store.isApproved('cresus','tester@example.com'),true);
    await store.request('cresus','tester@example.com');
    assert.equal((await store.list('cresus')).length,1);
    assert.equal(await store.isApproved('cresus','tester@example.com'),true);
    assert.equal(await store.decide('cresus','tester@example.com','deny','owner@example.com'),true);
    assert.equal(await store.isApproved('cresus','tester@example.com'),false);
    await store.request('cresus','tester@example.com');
    assert.equal(await store.isApproved('cresus','tester@example.com'),false);
    assert.equal((await store.list('cresus'))[0].reviewed_by,'owner@example.com');
  } finally {sqlite.close();}
});

test('Even if app stores shared a database, app_id is required for every read/update',async()=>{
  const {sqlite,store}=fixture();
  try {
    await store.request('hermes','same@example.com');
    await store.request('cresus','same@example.com');
    await store.decide('hermes','same@example.com','approve','owner@example.com');
    assert.equal(await store.isApproved('hermes','same@example.com'),true);
    assert.equal(await store.isApproved('cresus','same@example.com'),false);
    assert.equal((await store.list('hermes')).length,1);
    assert.equal((await store.list('cresus')).length,1);
    assert.equal(await store.decide('other-app','same@example.com','approve','owner@example.com'),false);
  } finally {sqlite.close();}
});

test('D1 approval fails closed for nonexistent request and unsupported decisions',async()=>{
  const {sqlite,store}=fixture();
  try{
    assert.equal(await store.decide('cresus','unknown@example.com','approve','owner@example.com'),false);
    await store.request('cresus','known@example.com');
    await assert.rejects(store.decide('cresus','known@example.com','other','owner@example.com'),/approve or deny/);
    assert.equal(await store.isApproved('cresus','known@example.com'),false);
  } finally {sqlite.close();}
});
