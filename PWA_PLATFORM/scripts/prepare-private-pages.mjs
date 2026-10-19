#!/usr/bin/env node
import {existsSync, mkdirSync, writeFileSync, rmSync} from 'node:fs';
import {resolve, join} from 'node:path';
import {pathToFileURL} from 'node:url';
import {
  planPrivatePagesNamespace, validatePrivatePagesNamespace,
  renderUnpublishedPlaceholder,
} from '../deployment/private-pages-namespace.mjs';

const HEADERS = [
  '/*',
  '  Cache-Control: no-store',
  '  X-Robots-Tag: noindex, nofollow, noarchive',
  '  X-Content-Type-Options: nosniff',
  '  Referrer-Policy: no-referrer',
  '  Content-Security-Policy: default-src \'none\'; style-src \'unsafe-inline\'; base-uri \'none\'; form-action \'none\'',
  '',
].join('\n');

/**
 * Creates inert filesystem examples, never Cloudflare projects or branch deploys.
 * The output path must be new so no existing application or evidence is overwritten.
 */
export function preparePrivatePagesPlaceholders(outDir, {additionalAppIds=[]}={}) {
  const plan=planPrivatePagesNamespace({additionalAppIds});
  const verified=validatePrivatePagesNamespace(plan);
  if(!verified.ok)throw new Error('Unsafe private Pages plan: '+verified.errors.join('; '));
  if(typeof outDir!=='string'||!outDir.trim())throw new TypeError('Explicit output directory is required');
  const path=resolve(outDir);
  if(existsSync(path))throw new Error('Refusing to overwrite existing destination');
  mkdirSync(path,{recursive:true});
  try {
    for(const env of plan.environments) {
      const folder=join(path,'branches',env.branch);
      mkdirSync(folder,{recursive:true});
      // Additional app placeholders must never silently pretend to be active.
      const html=additionalAppIds.includes(env.branch)
        ? renderFutureApplicationPlaceholder(env.branch)
        : renderUnpublishedPlaceholder(env.branch);
      writeFileSync(join(folder,'index.html'),html,{flag:'wx'});
      writeFileSync(join(folder,'_headers'),HEADERS,{flag:'wx'});
    }
    const portalFolder=join(path,'future-portal');
    mkdirSync(portalFolder,{recursive:true});
    writeFileSync(join(portalFolder,'index.html'),renderUnpublishedPlaceholder('edenosportal'),{flag:'wx'});
    writeFileSync(join(portalFolder,'_headers'),HEADERS,{flag:'wx'});
    writeFileSync(join(path,'namespace-intent.json'),JSON.stringify(plan,null,2)+'\n',{flag:'wx'});
    writeFileSync(join(path,'UNPUBLISHED_README.txt'),
      'DESIRED NAME RESERVATIONS ONLY. These files have not been uploaded to Cloudflare. '+
      'Do not publish until independent Cloudflare Access, branch and hash-preview protection, '+
      'source and user-data isolation, owner identity, and direct-origin containment pass physical tests.\n',
      {flag:'wx'});
  }catch(error) {
    rmSync(path,{force:true,recursive:true});
    throw error;
  }
  return {outputDirectory:path,branchCount:plan.environments.length,
    futurePortal:plan.futurePortal.requestedUrl,published:false,securityAccepted:false};
}

function renderFutureApplicationPlaceholder(appId) {
  // appId is validated DNS-safe and never interpreted as HTML markup.
  return '<!doctype html><html lang="en"><head><meta charset="utf-8">'+
    '<meta name="robots" content="noindex,nofollow,noarchive">'+
    '<meta name="viewport" content="width=device-width,initial-scale=1">'+
    '<meta http-equiv="Content-Security-Policy" content="default-src &#39;none&#39;">'+
    '<title>'+appId+' — private preview intent</title></head><body>'+
    '<h1>'+appId+'</h1><p>Private application placeholder only. Not deployed or activated.</p></body></html>\n';
}

if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href) {
  const argv=process.argv.slice(2);
  const at=argv.indexOf('--output');
  const output=at>=0?argv[at+1]:null;
  if(!output) {
    console.log(JSON.stringify(planPrivatePagesNamespace(),null,2));
  } else {
    try {
      const value=preparePrivatePagesPlaceholders(output);
      console.log(JSON.stringify(value,null,2));
    }catch(error) {
      console.error('PRIVATE_PAGES_PREPARE_BLOCKED: '+error.message);
      process.exitCode=1;
    }
  }
}
