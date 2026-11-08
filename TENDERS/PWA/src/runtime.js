// Base-path contract for standalone and RAVENaIntelligence subpath deployments.
// Browser-only API routes stay same-origin so Pages can authorize and route to Netlify.
const detectedBase = typeof import.meta.env === "object" ? import.meta.env.BASE_URL : "/";
export function appPath(resource,base=detectedBase||"/"){
 if(typeof resource!=="string"||!resource||resource.startsWith("/")||resource.includes("..")||/[?#\\]/.test(resource))throw new Error("Unsafe TENDERS app resource.");
 if(!/^\/[a-zA-Z0-9/_-]*\/$/.test(base)||base.includes("//"))throw new Error("Invalid absolute app base path.");
 return base+resource;
}
