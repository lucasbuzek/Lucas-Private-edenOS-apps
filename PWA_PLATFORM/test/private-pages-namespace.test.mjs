import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, existsSync, readFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {
  plannedBranchAlias, planPrivatePagesNamespace, validatePrivatePagesNamespace,
  renderUnpublishedPlaceholder
} from '../deployment/private-pages-namespace.mjs';
import {preparePrivatePagesPlaceholders} from '../scripts/prepare-private-pages.mjs';

test('canonical private Pages namespace includes owner, both standalone apps and future environments',()=>{
  const p=planPrivatePagesNamespace();
  assert.deepEqual(validatePrivatePagesNamespace(p),{ok:true,errors:[]});
  const urls=p.environments.map(e=>e.requestedUrl);
  assert.deepEqual(urls,[
    'https://lucas.edenosprivate.pages.dev',
    'https://hermes.edenosprivate.pages.dev',
    'https://cresus.edenosprivate.pages.dev',
    'https://elysium.edenosprivate.pages.dev',
    'https://slindokuhle.edenosprivate.pages.dev',
    'https://lucastesting.edenosprivate.pages.dev',
  ]);
  assert.equal(p.privateRoot,'https://edenosprivate.pages.dev');
  assert.equal(p.futurePortal.requestedUrl,'https://edenosportal.pages.dev');
  assert.equal(p.futurePortal.project,'edenosportal');
  assert.equal(p.futurePortal.deployed,false);
  assert.equal(p.futurePortal.productionPublicationAllowed,false);
  assert.equal(p.status,'DESIRED_NAMES_ONLY');
  assert.ok(p.environments.every(e=>e.availability==='UNVERIFIED_NOT_PROVISIONED'&&
    !e.deployed&&!e.accessAccepted));
});

test('owner-admin remains separate from HERMES and CRESUS member approvals',()=>{
  const entries=planPrivatePagesNamespace().environments;
  const owner=entries.find(e=>e.branch==='lucas');
  assert.equal(owner.kind,'owner-admin');
  assert.equal(owner.access,'owner-only');
  assert.equal(owner.appId,null);
  const apps=entries.filter(e=>e.appId);
  assert.deepEqual(apps.map(e=>e.appId),['hermes','cresus']);
  assert.ok(apps.every(e=>e.access==='approved-app-testers'&&
    e.appIsolation==='separate-app-runtime-data-and-identity-required'));
  for(const e of entries.filter(e=>e.kind==='future-environment')) {
    assert.equal(e.access,'owner-only-until-authorized');
  }
});

test('both Cloudflare app manifests request only their own private Pages branch aliases',()=>{
  for(const app of ['hermes','cresus']){
    const path=app==='hermes'?'hermes.cloudflare.closed.manifest.json':'cresus.worker.manifest.json';
    const manifest=JSON.parse(readFileSync(new URL('../examples/'+path,import.meta.url),'utf8'));
    const entry=manifest.deployment.desiredPagesEntry;
    assert.equal(entry.projectIntent,'edenosprivate');
    assert.equal(entry.branchIntent,app);
    assert.equal(entry.requestedUrl,'https://'+app+'.edenosprivate.pages.dev');
    assert.equal(entry.status,'UNVERIFIED_NOT_PROVISIONED');
    assert.equal(entry.branchAndHashPreviewsRequireAccess,true);
    assert.equal(entry.independentAppRuntimeAndDataRequired,true);
    assert.equal(manifest.deployment.targetId,'');
    assert.equal(manifest.deployment.siteUrl,'');
  }
});

test('extra app names can be planned without granting access or creating sites',()=>{
  const p=planPrivatePagesNamespace({additionalAppIds:['mammon']});
  assert.equal(validatePrivatePagesNamespace(p).ok,true);
  const extra=p.environments.find(e=>e.branch==='mammon');
  assert.equal(extra.requestedUrl,'https://mammon.edenosprivate.pages.dev');
  assert.equal(extra.deployed,false);
  assert.equal(extra.accessAccepted,false);
});

test('no duplicate aliases, unsafe names, cross-project escape or false deployment claims',()=>{
  assert.throws(()=>planPrivatePagesNamespace({additionalAppIds:['hermes']}),/reserved/);
  assert.throws(()=>planPrivatePagesNamespace({additionalAppIds:['../../admin']}),/DNS-safe/);
  assert.throws(()=>plannedBranchAlias('Lucas'),/DNS-safe/);
  let p=planPrivatePagesNamespace();
  p.environments[0].deployed=true;
  assert.equal(validatePrivatePagesNamespace(p).ok,false);
  p=planPrivatePagesNamespace();
  p.environments[0].access='approved-app-testers';
  assert.equal(validatePrivatePagesNamespace(p).ok,false);
  p=planPrivatePagesNamespace();
  p.environments[0].requestedUrl='https://attacker.example';
  assert.equal(validatePrivatePagesNamespace(p).ok,false);
  p=planPrivatePagesNamespace();
  p.status='DEPLOYED';
  assert.equal(validatePrivatePagesNamespace(p).ok,false);
  p=planPrivatePagesNamespace();
  p.futurePortal.deployed=true;
  assert.equal(validatePrivatePagesNamespace(p).ok,false);
});

test('placeholder renderer never exposes an unlocked admin login or actual app state',()=>{
  for(const key of ['lucas','hermes','cresus','elysium','slindokuhle','lucastesting','edenosportal']){
    const html=renderUnpublishedPlaceholder(key);
    assert.match(html,/<meta name="robots" content="noindex,nofollow,noarchive">/);
    assert.match(html,/Not launched|not activated/);
    assert.doesNotMatch(html,/<form\b|data-sitekey=|token=|api\/admin|admin-access=|<script\b/i);
  }
  assert.throws(()=>renderUnpublishedPlaceholder('not-selected'),/Unknown/);
});

test('generates inert branch-alias placeholders and separate portal without changing existing files',()=>{
  const parent=mkdtempSync(join(tmpdir(),'edenos-pages-names-'));
  const out=join(parent,'desired');
  try {
    const status=preparePrivatePagesPlaceholders(out);
    assert.equal(status.branchCount,6);
    assert.equal(status.published,false);
    assert.equal(status.securityAccepted,false);
    assert.ok(existsSync(join(out,'branches','lucas','index.html')));
    assert.ok(existsSync(join(out,'branches','elysium','index.html')));
    assert.ok(existsSync(join(out,'branches','slindokuhle','index.html')));
    assert.ok(existsSync(join(out,'branches','lucastesting','index.html')));
    assert.ok(existsSync(join(out,'branches','hermes','index.html')));
    assert.ok(existsSync(join(out,'branches','cresus','index.html')));
    assert.ok(existsSync(join(out,'future-portal','index.html')));
    assert.ok(existsSync(join(out,'future-portal','_headers')));
    assert.match(readFileSync(join(out,'UNPUBLISHED_README.txt'),'utf8'),/do not publish/i);
    const stored=JSON.parse(readFileSync(join(out,'namespace-intent.json'),'utf8'));
    assert.deepEqual(validatePrivatePagesNamespace(stored),{ok:true,errors:[]});
    assert.throws(()=>preparePrivatePagesPlaceholders(out),/Refusing to overwrite/);
  } finally {rmSync(parent,{recursive:true,force:true});}
});


test('private root, all aliases, immutable hash previews and app identity require explicit live gates',()=>{
  const p=planPrivatePagesNamespace();
  assert.ok(Object.values(p.securityRequirements).every(x=>x===true));
  for(const e of p.environments){
    assert.equal(e.actualApplicationDeployedHere,false);
    assert.equal(e.placeholderOnly,true);
  }
  for(const key of Object.keys(p.securityRequirements)){
    const broken=planPrivatePagesNamespace();
    broken.securityRequirements[key]=false;
    assert.equal(validatePrivatePagesNamespace(broken).ok,false,'must enforce '+key);
  }
});
