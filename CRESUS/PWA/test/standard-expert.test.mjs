import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
const root = new URL('../', import.meta.url);
const read = path => readFileSync(new URL(path, root), 'utf8');

test('Standard and Advanced Expert UI are selectable and source-backed', () => {
  const html = read('public/index.html'), app = read('public/app.js');
  assert.match(html, /data-presentation="standard"/);
  assert.match(html, /data-presentation="expert"/);
  for (const id of ['standardDesk','expertDesk','verifiedRuntime','presentationSummary'])
    assert.match(html,new RegExp('id="'+id+'"'));
  for (const topic of ['Evidence matrix','Point-in-time analysis','ZACCHAEUS','THE GILDED ORDER','Provider capabilities'])
    assert.ok(html.includes(topic),'Missing original specialist workflow: '+topic);
  assert.match(app,/function renderPresentation\(\)/);
  assert.match(app,/store\.set\('cresus\.presentation'/);
  assert.match(app,/selectWorkspace\(button\.dataset\.cresusWorkspace\)/);
  assert.match(app,/\$\('composer'\)\.requestSubmit\(\)/);
  assert.ok(!html.includes('simulated portfolio'));
});
test('Expert and Standard share the same original CRESUS backend',()=>{
  const worker=read('src/worker.js');
  const app=read('public/app.js');
  assert.match(app,/api\('\/api\/chat'/);
  assert.match(worker,/\/api\/intelligence/);
  assert.match(worker,/from '\.\/provider-choice\.js'/);
  assert.match(app,/state\.presentation === 'expert'/);
  assert.match(app,/state\.mode = state\.presentation === 'expert' \? 'expert' : 'simple'/);
});
test('RAVENnest account and D1 cannot overwrite the original production resources',()=>{
  const config=read('wrangler.ravensnest-preview.toml');
  assert.match(config,/name = "cresus-ravensnest-preview"/);
  assert.match(config,/database_name = "cresus_ravensnest_preview"/);
  assert.match(config,/ACCESS_TEAM_DOMAIN = "lucasravensnest.cloudflareaccess.com"/);
  assert.doesNotMatch(config,/database_id = "deafac98-8efa-414b-9561-30904ac1f9b9"/);
});
