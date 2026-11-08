import {authenticated} from "../_lib/auth.js";
export async function onRequest(context){
 const path=new URL(context.request.url).pathname;
 // Exact /app/api routes handle authenticated reads and mutations themselves.
 if(path.startsWith("/app/api/"))return context.next();
 if(context.request.method!=="GET"&&context.request.method!=="HEAD")return new Response("Method not allowed",{status:405});
 try{const user=await authenticated(context);if(!user)return Response.redirect(new URL("/login/?next="+encodeURIComponent(path),context.request.url),302)}catch{return new Response("Authentication temporarily unavailable",{status:503})}
 return context.next();
}
