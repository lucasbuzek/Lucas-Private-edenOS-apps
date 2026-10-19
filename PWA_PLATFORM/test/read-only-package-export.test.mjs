import test from 'node:test';
import assert from 'node:assert/strict';
import {createReadOnlyActionBridge,readonlyActionNames}
  from '@edenos/pwa-platform/intelligence/read-only-actions';

test('PWA self-resolution exports only the reviewed read-only Actions surface',()=>{
  assert.equal(typeof createReadOnlyActionBridge,'function');
  assert.deepEqual(readonlyActionNames(),['github.repository.metadata','dropbox.folder.list']);
});
