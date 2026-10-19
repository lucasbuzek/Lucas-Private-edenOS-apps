import {createEmailDownloadService,createCloudflareEmailMailer,
  validateEmailLinkReleases} from './email-links.mjs';
import {createD1EmailTicketStore} from './email-tickets.mjs';
import {createGitHubReleaseReader} from './github-release.mjs';
import {d1WaitlistStore} from '../closed-testing/d1.mjs';
import {createD1ReleaseControls} from './release-controls.mjs';

/**
 * Dedicated backend bound to edenosportal Pages Functions.
 * No public issue/grant route: only Lucas's independently Access-authenticated
 * owner hub can call issueApproved() with an authenticated owner principal.
 * All D1 and GitHub credentials are Worker secrets/bindings, never static files.
 */
export function createCloudflareEmailDownloadWorker({releases,fetchImpl=fetch}={}) {
  if(!validateEmailLinkReleases(releases).ok||typeof fetchImpl!=='function')
    throw new TypeError('Physically accepted manifest and transport required');
  const prepare=env=>{
    if(!env || typeof env.OWNER_EMAIL!=='string' ||
       typeof env.EMAIL_FROM!=='string'||typeof env.GITHUB_READ_TOKEN!=='string'||
       !env.GITHUB_READ_TOKEN.trim()||typeof env.EMAIL?.send!=='function'||
       typeof env.SHARING_DB?.prepare!=='function' ||
       typeof env.TICKET_DB?.batch!=='function')
      throw new Error('Backend email, release read token and dedicated D1 bindings unverified');
    const store=d1WaitlistStore(env.SHARING_DB);
    const controls=createD1ReleaseControls({db:env.TICKET_DB,releases});
    const reader=createGitHubReleaseReader({
      token:env.GITHUB_READ_TOKEN,fetchImpl,
      allowedRepositories:[...new Set(releases.map(r=>r.source.repository))],
    });
    return createEmailDownloadService({
      releases,origin:'https://edenosportal.pages.dev/',ownerEmail:env.OWNER_EMAIL,
      tickets:createD1EmailTicketStore(env.TICKET_DB),
      approved:(appId,email)=>store.isApproved(appId,email),
      releaseEnabled:(appId,releaseId)=>controls.isEnabled(appId,releaseId),
      sendEmail:createCloudflareEmailMailer({binding:env.EMAIL,from:env.EMAIL_FROM}),
      readArtifact:release=>reader.read(release),
    });
  };
  return Object.freeze({
    async fetch(request,env) {
      try{return await prepare(env).fetch(request);}
      catch{return new Response('Verified email download service unavailable',{
        status:503,headers:{'cache-control':'no-store','x-robots-tag':'noindex,nofollow'},
      });}
    },
    async issueApproved(issue,env) {
      try {return await prepare(env).issue(issue);}
      catch{return {state:'UNAVAILABLE',reason:'PRIVATE_EMAIL_GATE_NOT_CONFIGURED'};}
    },
    async listAccepted(env) {
      try{
        if(typeof env?.TICKET_DB?.prepare!=='function')return [];
        return await createD1ReleaseControls({db:env.TICKET_DB,releases}).list();
      }catch{return [];}
    },
    async setAcceptedState({principal,appId,releaseId,enabled},env) {
      const owner=String(env?.OWNER_EMAIL||'').trim().toLowerCase();
      if(!principal?.id||!owner||principal.email?.toLowerCase()!==owner||
        !principal.allowedApps?.includes('lucas-admin'))
        return {state:'DENIED',reason:'OWNER_LOGIN_REQUIRED'};
      try{
        const controls=createD1ReleaseControls({db:env.TICKET_DB,releases});
        const changed=await controls.setEnabled({
          appId,releaseId,enabled,reviewer:owner,at:Date.now(),
        });
        return changed?{state:'UPDATED',enabled}:{state:'DENIED',reason:'RELEASE_NOT_ACCEPTED'};
      }catch{return {state:'UNAVAILABLE',reason:'RELEASE_SETTINGS_UNAVAILABLE'};}
    },
  });
}
