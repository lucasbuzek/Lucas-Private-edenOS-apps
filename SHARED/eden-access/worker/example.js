import {requireIdentity} from "./auth.js";

export default {
  async fetch(request, env){
    const url=new URL(request.url);
    if(url.pathname==="/health") return Response.json({ok:true});

    if(url.pathname.startsWith("/api/")){
      let identity;
      try { identity=requireIdentity(request); }
      catch(response){ return response; }
      return Response.json({ok:true,user:{provider:identity.provider,subject:identity.subject}});
    }

    return env.ASSETS ? env.ASSETS.fetch(request) : new Response("Not found",{status:404});
  }
};
