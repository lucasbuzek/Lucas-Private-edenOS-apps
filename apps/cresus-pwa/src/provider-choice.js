import { generate } from './providers.js';
const AVAILABLE = ['workers-ai', 'gemini', 'anthropic'];
export function providerChoices(env) {
  return [
    { id:'codex-cloud', label:'Codex Cloud', available:false, reason:'No verified account-based task connector' },
    { id:'workers-ai', label:'Cloudflare Workers AI', available:!!env.AI && !!env.WORKERS_AI_MODEL },
    { id:'gemini', label:'Gemini', available:!!env.GEMINI_API_KEY && !!env.GEMINI_MODEL },
    { id:'anthropic', label:'Anthropic', available:!!env.ANTHROPIC_API_KEY && !!env.ANTHROPIC_MODEL },
    { id:'none', label:'Set up later', available:true }
  ];
}
export async function providerForUser(env,email) {
  const row=await env.DB.prepare('SELECT provider FROM intelligence_preferences WHERE email = ?').bind(email).first();
  // Existing users retain the previously configured deployment provider until they choose.
  return row?.provider || (AVAILABLE.includes((env.PROVIDER || 'workers-ai').toLowerCase()) ? (env.PROVIDER || 'workers-ai').toLowerCase() : 'workers-ai');
}
export async function setProviderForUser(env,email,provider) {
  if (typeof provider !== 'string') throw new ProviderSelectionError('Unknown provider',400);
  const choice=providerChoices(env).find(p=>p.id===provider);
  if(!choice) throw new ProviderSelectionError('Unknown provider',400);
  if(!choice.available) throw new ProviderSelectionError('Provider is not connected',409);
  await env.DB.prepare(`INSERT INTO intelligence_preferences(email,provider) VALUES (?,?)
    ON CONFLICT(email) DO UPDATE SET provider=excluded.provider,updated_at=datetime('now')`).bind(email,provider).run();
  return {provider};
}
export class ProviderSelectionError extends Error {constructor(message,status){super(message);this.status=status;}}
export async function generateForProvider(env,provider,system,history) {
  if(!provider || provider==='none')throw new ProviderSelectionError('Choose an intelligence provider in Settings',409);
  if(provider==='codex-cloud')throw new ProviderSelectionError('Codex Cloud account connector is not verified',501);
  if(!AVAILABLE.includes(provider)||!providerChoices(env).find(p=>p.id===provider)?.available)
    throw new ProviderSelectionError('Selected provider is unavailable',503);
  return generate({...env,PROVIDER:provider},system,history);
}
