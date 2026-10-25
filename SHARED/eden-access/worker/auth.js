const PROVIDERS={
  google:{issuer:"https://accounts.google.com"},
  microsoft:{issuer:"https://login.microsoftonline.com/common/v2.0"},
  apple:{issuer:"https://appleid.apple.com"}
};

export function unauthorized(){return new Response("Authentication required",{status:401});}

export function getTrustedIdentity(request){
  // Adapter boundary. In production, populate only after cryptographic verification
  // by the configured gateway/OIDC adapter. Never trust client-supplied identity headers.
  const subject=request.headers.get("X-EDEN-Verified-Subject");
  const provider=request.headers.get("X-EDEN-Verified-Provider");
  if(!subject||!provider) return null;
  return {subject,provider};
}

export function requireIdentity(request){
  const identity=getTrustedIdentity(request);
  if(!identity) throw unauthorized();
  return identity;
}

export {PROVIDERS};
