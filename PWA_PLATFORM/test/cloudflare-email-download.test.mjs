import test from 'node:test';
import assert from 'node:assert/strict';
import {createCloudflareEmailDownloadWorker} from '../software-sharing/cloudflare-email-download.mjs';

const origin='https://edenosportal.pages.dev';

test('private email download Worker never enables itself with missing secrets or D1',async()=>{
  const worker=createCloudflareEmailDownloadWorker({releases:[]});
  const request=new Request(origin+'/download/redeem');
  assert.equal((await worker.fetch(request,{})).status,503);
  assert.deepEqual(await worker.issueApproved({
    principal:{id:'owner',email:'owner@example.com',allowedApps:['lucas-admin']},
    email:'tester@example.com',appId:'hermes',releaseId:'v01'
  },{}),{state:'UNAVAILABLE',reason:'PRIVATE_EMAIL_GATE_NOT_CONFIGURED'});
  assert.deepEqual(await worker.listAccepted({}),[]);
});

test('unreviewed release cannot be injected to enable GitHub asset access',()=>{
  assert.throws(()=>createCloudflareEmailDownloadWorker({
    releases:[{appId:'hermes',releaseId:'v01',source:{
      kind:'github-release',repository:'lucasbuzek/Lucas-Private-edenOS-apps',assetId:77
    },approvedForSharing:false,physicalAcceptance:false}],
  }),/Physically accepted/);
});
