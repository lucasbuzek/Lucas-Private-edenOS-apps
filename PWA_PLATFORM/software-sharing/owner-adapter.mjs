/**
 * Inject this adapter into the independently Cloudflare Access-protected
 * Lucas owner-hub service. Only the owner hub calls these RPC functions.
 * This bridge does not expose an unauthenticated HTTP issuance endpoint.
 */
export function createEmailReleaseOwnerAdapter({emailDownloadWorker,env}={}) {
  if(typeof emailDownloadWorker?.listAccepted!=='function' ||
     typeof emailDownloadWorker?.issueApproved!=='function' ||
     typeof emailDownloadWorker?.setAcceptedState!=='function')
    throw new TypeError('Trusted email release Worker service interface required');
  return Object.freeze({
    list:()=>emailDownloadWorker.listAccepted(env),
    issue:request=>emailDownloadWorker.issueApproved(request,env),
    setEnabled:request=>emailDownloadWorker.setAcceptedState(request,env),
  });
}
