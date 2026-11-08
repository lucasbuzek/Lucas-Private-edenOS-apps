import {readFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
export function parseEnv(content){
  return Object.fromEntries(content.split(/\r?\n/).filter(line=>line.trim()&&!line.startsWith('#')).map(line=>{
    const i=line.indexOf('='); if(i<1)throw new Error('Invalid env entry');
    return [line.slice(0,i),line.slice(i+1).replace(/^"|"$/g,'')];
  }));
}
export function checkConfig(env, compose){
  const errors=[];
  for(const key of ['POSTIZ_IMAGE','PUBLIC_URL','JWT_SECRET','POSTGRES_PASSWORD','TEMPORAL_POSTGRES_PASSWORD']){
    if(!env[key]||/GENERATE|PLACEHOLDER|REPLACE/i.test(env[key])) errors.push(`${key}: not configured`);
  }
  if(!/^ghcr\.io\/gitroomhq\/postiz-app:(?:v\d+\.\d+\.\d+)$/.test(env.POSTIZ_IMAGE||'')) errors.push('POSTIZ_IMAGE: a reviewed version tag is required');
  const secrets=['JWT_SECRET','POSTGRES_PASSWORD','TEMPORAL_POSTGRES_PASSWORD'];
  for(const k of secrets)if((env[k]||'').length<32)errors.push(`${k}: use at least 32 random characters`);
  if(new Set(secrets.map(k=>env[k])).size!==3)errors.push('Secrets must be distinct');
  let url;
  try{url=new URL(env.PUBLIC_URL);}catch{errors.push('PUBLIC_URL must be an absolute URL');}
  if(url){
    const local=['localhost','127.0.0.1','[::1]'].includes(url.hostname);
    if(url.protocol!=='https:'&&!local) errors.push('Nonlocal PUBLIC_URL must use HTTPS');
    if(env.BRAGI_DISABLE_REGISTRATION!=='true'&&!local) errors.push('Public registration is prohibited');
  }
  if(!compose.includes('127.0.0.1:4007:5000'))errors.push('Postiz host port must bind to loopback');
  if(compose.includes(':latest'))errors.push('Unpinned latest image forbidden');
  if(/\bMAMMON\b|\bFAMA_TOKEN\b/.test(compose))errors.push('Unrelated governor integration forbidden');
  return errors;
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const [env,compose]=await Promise.all([
    readFile(resolve(root,'postiz/.env'),'utf8').then(parseEnv),
    readFile(resolve(root,'postiz/compose.yaml'),'utf8')
  ]);
  const errors=checkConfig(env,compose);
  if(errors.length){console.error(errors.map(x=>`FAIL ${x}`).join('\n'));process.exitCode=1;}
  else console.log('Preflight passed: pinned Postiz, private credentials, loopback binding, safe registration mode. Runtime and provider OAuth NOT tested.');
}
