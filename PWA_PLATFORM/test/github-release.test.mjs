import test from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {createGitHubReleaseReader,validateGitHubAsset} from '../software-sharing/github-release.mjs';

const bytes=new TextEncoder().encode('EDEN private verified release bytes.');
const sha=createHash('sha256').update(bytes).digest('hex');
const release={
 appId:'hermes',releaseId:'v01',filename:'HERMES-v0.1.zip',
 sizeBytes:bytes.length,sha256:sha,
 approvedForSharing:true,physicalAcceptance:true,
 source:{kind:'github-release',repository:'lucasbuzek/Lucas-Private-edenOS-apps',assetId:731001},
};
function mock({redirect=false,location='https://release-assets.githubusercontent.com/signed-test',tamper=false}={}){
 const observed=[];
 const fetchImpl=async(url,opts)=>{
  observed.push({url,opts});
  const contentType=opts.headers?.accept;
  if(contentType==='application/vnd.github+json'){
   return Response.json({id:731001,name:release.filename,size:bytes.length,
     state:'uploaded',digest:'sha256:'+sha});
  }
  if(redirect && url.startsWith('https://api.github.com/')){
   return new Response(null,{status:302,headers:{location}});
  }
  const value=tamper?new Uint8Array(bytes.map(x=>x===69?70:x)):bytes;
  return new Response(value,{status:200,
    headers:{'content-type':'application/octet-stream','content-length':String(value.length)}});
 };
 return {observed,fetchImpl};
}
test('private GitHub Releases adapter verifies exact asset metadata, bytes and SHA256',async()=>{
 const f=mock();
 const reader=createGitHubReleaseReader({allowedRepositories:['lucasbuzek/Lucas-Private-edenOS-apps'],token:'mock-read-only-token',fetchImpl:f.fetchImpl});
 const out=await reader.read(release);
 assert.deepEqual(out,bytes);
 assert.equal(f.observed.length,2);
 assert.equal(f.observed[0].url,'https://api.github.com/repos/lucasbuzek/Lucas-Private-edenOS-apps/releases/assets/731001');
 assert.equal(f.observed[0].opts.headers.authorization,'Bearer mock-read-only-token');
});
test('GitHub private bearer is not forwarded to approved release-asset CDN',async()=>{
 const f=mock({redirect:true});
 const reader=createGitHubReleaseReader({allowedRepositories:['lucasbuzek/Lucas-Private-edenOS-apps'],token:'private-test-token',fetchImpl:f.fetchImpl});
 assert.deepEqual(await reader.read(release),bytes);
 assert.equal(f.observed.length,3);
 assert.equal(f.observed[2].url,'https://release-assets.githubusercontent.com/signed-test');
 assert.equal('authorization' in f.observed[2].opts.headers,false);
});
test('GitHub asset provenance, binary digest and redirect host fail closed',async()=>{
 const bad=mock({tamper:true});
 await assert.rejects(createGitHubReleaseReader({allowedRepositories:['lucasbuzek/Lucas-Private-edenOS-apps'],token:'test',fetchImpl:bad.fetchImpl}).read(release),
   /checksum/);
 const redirect=mock({redirect:true,location:'https://attacker.example/malicious.zip'});
 await assert.rejects(createGitHubReleaseReader({allowedRepositories:['lucasbuzek/Lucas-Private-edenOS-apps'],token:'test',fetchImpl:redirect.fetchImpl}).read(release),
   /redirect destination/);
 const bogus={...release,source:{...release.source,assetId:0}};
 await assert.rejects(createGitHubReleaseReader({allowedRepositories:['lucasbuzek/Lucas-Private-edenOS-apps'],token:'test',fetchImpl:mock().fetchImpl}).read(bogus),
   /Unverified/);
 assert.equal(validateGitHubAsset({kind:'github-release',repository:'attacker/repo',assetId:4,
   authorization:'Bearer leak'}),false);
});
test('an unverified JSON response or incorrect length is never delivered',async()=>{
 const f=mock();
 const json=async(url,opts)=>opts.headers?.accept==='application/octet-stream'?
   Response.json({message:'Not Found'}):f.fetchImpl(url,opts);
 await assert.rejects(createGitHubReleaseReader({allowedRepositories:['lucasbuzek/Lucas-Private-edenOS-apps'],token:'test',fetchImpl:json}).read(release),
   /Unexpected GitHub API/);
 const invalid={...release,sizeBytes:64*1024*1024+1};
 await assert.rejects(createGitHubReleaseReader({allowedRepositories:['lucasbuzek/Lucas-Private-edenOS-apps'],token:'test',fetchImpl:f.fetchImpl}).read(invalid),
   /oversized/);
});
