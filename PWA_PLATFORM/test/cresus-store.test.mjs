import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { cresusWaitlistStore } from '../closed-testing/cresus-store.mjs';

const schema = String.raw`
CREATE TABLE users (
  email TEXT PRIMARY KEY,role TEXT NOT NULL DEFAULT 'member',
  status TEXT NOT NULL DEFAULT 'active', added_by TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),last_seen TEXT
)`;
function mock() {
  const db=new DatabaseSync(':memory:');
  db.exec(schema);
  const d1={
    prepare(sql) {
      const stmt=db.prepare(sql);
      return {
        bind(...args) {
          return {
            async first(){return stmt.get(...args) || null;},
            async run(){const r=stmt.run(...args);return {meta:{changes:Number(r.changes)}};},
            async all(){return {results:stmt.all(...args)};},
          };
        },
        async all(){return {results:stmt.all()};},
      };
    },
  };
  return {db,store:cresusWaitlistStore(d1)};
}

test('CRESUS reuses its original member statuses for waitlist, approval and denial',async()=>{
  const f=mock();
  try {
    await f.store.request('cresus','tester@example.com');
    assert.equal(await f.store.isApproved('cresus','tester@example.com'),false);
    assert.equal((await f.store.list('cresus')).length,1);
    assert.equal(await f.store.decide('cresus','tester@example.com','approve','owner@example.com'),true);
    assert.equal(await f.store.isApproved('cresus','tester@example.com'),true);
    await f.store.request('cresus','tester@example.com');
    assert.equal(await f.store.isApproved('cresus','tester@example.com'),true);
    assert.equal(await f.store.decide('cresus','tester@example.com','deny','owner@example.com'),true);
    assert.equal(await f.store.isApproved('cresus','tester@example.com'),false);
    assert.equal(f.db.prepare('SELECT status FROM users WHERE email=?').get('tester@example.com').status,'disabled');
  } finally {f.db.close();}
});

test('CRESUS adapter refuses any cross-app membership reads/writes or approvals',async()=>{
  const f=mock();
  try {
    await assert.rejects(f.store.request('hermes','same@example.com'),/cannot be used/);
    await assert.rejects(f.store.decide('hermes','same@example.com','approve','owner@example.com'),/cannot be updated/);
    assert.equal(await f.store.isApproved('hermes','same@example.com'),false);
  }finally{f.db.close();}
});

test('CRESUS waitlist never overwrites or demotes an existing admin record',async()=>{
  const f=mock();
  try{
    f.db.prepare("INSERT INTO users (email,role,status,added_by) VALUES (?, 'admin', 'active','owner')").run('owner@example.com');
    await f.store.request('cresus','owner@example.com');
    assert.equal(f.db.prepare('SELECT status FROM users WHERE email=?').get('owner@example.com').status,'active');
    assert.equal(await f.store.decide('cresus','owner@example.com','deny','owner@example.com'),false);
    assert.equal((await f.store.list('cresus')).length,0);
  } finally{f.db.close();}
});
