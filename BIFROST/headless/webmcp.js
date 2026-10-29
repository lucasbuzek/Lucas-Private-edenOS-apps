"use strict";
/* BIFROST original Headless dashboard: browser-native WebMCP, NOT backend MCP.
 * All browser tools delegate to the existing bounded local shortNameCalls.
 * Expose no arbitrary scripts, provider operations or unverified remote commands.
 */
(() => {
  let registration = null;
  const el = id => document.getElementById(id);
  const status = message => {
    const output=el('webmcpState');
    if(output)output.textContent=message;
  };
  const denied = text => ({isError:true,content:[{type:'text',text}]});
  function revoke() {
    if(registration){ registration.abort(); registration=null; }
    status('WebMCP tools not registered');
  }
  async function enable() {
    revoke();
    if (!document.modelContext || typeof document.modelContext.registerTool !== 'function') {
      status('This browser has no WebMCP API. The standard BIFROST UI remains available.');
      return;
    }
    if (typeof token !== 'string' || !token) {
      status('Connect to the local BIFROST Headless session first.');
      return;
    }
    const session=token;
    const controller=new AbortController();
    try {
      const reply=await fetch('/api/webmcp/tools',{
        headers:{'X-Bifrost-Token':session},cache:'no-store',signal:controller.signal
      });
      if(!reply.ok)throw Error('Tool catalog permission denied');
      const catalog=await reply.json();
      if(!Array.isArray(catalog.tools)||catalog.tools.length>64)throw Error('Invalid catalog');
      let registered=0;
      for (const item of catalog.tools) {
        if(controller.signal.aborted || session!==token)throw Error('Session changed');
        if(typeof item.name!=='string' || !/^[a-zA-Z][a-zA-Z0-9_.-]{0,95}$/.test(item.name)
           || item.annotations?.readOnlyHint!==true)continue;
        const sourceName=item.name;
        const tool={
          name:'bifrost_'+sourceName.replace(/[^a-zA-Z0-9_]/g,'_'),
          description:'Read-only BIFROST local capability: '+sourceName+'. '+String(item.description||'').slice(0,300),
          inputSchema:{type:'object',properties:{},additionalProperties:false},
          annotations:{readOnlyHint:true,destructiveHint:false,untrustedContentHint:true},
          execute:async (args={}, context={}) => {
            if(controller.signal.aborted || session!==token)return denied('BIFROST session revoked');
            if(!args || typeof args!=='object' || Array.isArray(args) || Object.keys(args).length)
              return denied('This local BIFROST action accepts no arguments');
            try {
              const r=await fetch('/api/webmcp/call',{
                method:'POST',cache:'no-store',
                headers:{'X-Bifrost-Token':session,'Content-Type':'application/json'},
                body:JSON.stringify({name:sourceName,arguments:{}}),signal:context?.signal
              });
              if(!r.ok)throw Error('Denied by owner authority');
              const result=await r.json();
              if(controller.signal.aborted || session!==token)return denied('BIFROST session revoked');
              return result;
            } catch (_error) { return denied('Local BIFROST capability unavailable or denied'); }
          }
        };
        await document.modelContext.registerTool(tool,{signal:controller.signal});
        registered++;
      }
      if(controller.signal.aborted || session!==token){controller.abort();return;}
      registration=controller;
      status(registered+' read-only browser WebMCP tools registered in this tab.');
    }catch(_error){controller.abort();status('WebMCP activation unavailable or denied');}
  }
  function init() {
    if(!el('webmcpEnable'))return;
    el('webmcpEnable').addEventListener('click',enable);
    el('webmcpRevoke').addEventListener('click',revoke);
    window.addEventListener('pagehide',revoke);
  }
  document.addEventListener('DOMContentLoaded',init,{once:true});
})();
