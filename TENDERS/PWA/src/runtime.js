// Base-path contract for standalone and RAVENaIntelligence subpath deployments.
// Browser-only API routes stay same-origin so Pages can authorize and route to Netlify.
const detectedBase = typeof import.meta.env === "object" ? import.meta.env.BASE_URL : "/";
export function appPath(resource,base=detectedBase||"/"){
 if(typeof resource!=="string"||!/^[a-zA-Z0-9][a-zA-Z0-9_./-]*$/.test(resource)||resource.includes("..")||resource.includes("//"))throw new Error("Unsafe TENDERS app resource.");
 if(!/^\/(?:[a-zA-Z0-9_-]+\/)*$/.test(base))throw new Error("Invalid absolute app base path.");
 return base+resource;
}
