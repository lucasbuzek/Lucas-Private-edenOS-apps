import {test} from 'node:test';
import assert from 'node:assert/strict';
import {generate} from '../src/providers.js';
import {providerChoices} from '../src/provider-choice.js';

test('CRESUS exposes all current web provider adapters but gates missing credentials',()=>{
  const rows=providerChoices({AI:{},WORKERS_AI_MODEL:'m'});
  const byId=Object.fromEntries(rows.map(x=>[x.id,x]));
  assert.equal(byId['workers-ai'].available,true);
  for(const key of ['openai','mistral','gemini','anthropic','apple-native','codex-cloud'])
    assert.equal(byId[key].available,false,key);
});
test('OpenAI API and Mistral API reject absent credentials before making outbound requests',async()=>{
  await assert.rejects(generate({PROVIDER:'openai',OPENAI_MODEL:'gpt-4.1-mini'},'sys',[]),/not connected/);
  await assert.rejects(generate({PROVIDER:'mistral',MISTRAL_MODEL:'mistral-small-latest'},'sys',[]),/not connected/);
});
test('OpenAI adapter uses only fixed official endpoint, returns response and keeps token out of result',async()=>{
  const old=globalThis.fetch;
  try{
    globalThis.fetch=async (url,init)=>{
      assert.equal(url,'https://api.openai.com/v1/chat/completions');
      assert.equal(init.headers.authorization,'Bearer TEST_OPENAI_KEY');
      assert.equal(JSON.parse(init.body).model,'gpt-4.1-mini');
      assert.equal(JSON.parse(init.body).messages[0].role,'system');
      return {ok:true,json:async()=>({choices:[{message:{content:'Evidence qualified'}}]})};
    };
    assert.equal(await generate({PROVIDER:'openai',OPENAI_API_KEY:'TEST_OPENAI_KEY',OPENAI_MODEL:'gpt-4.1-mini'},'system',[{role:'user',content:'Test'}]),'Evidence qualified');
  }finally{globalThis.fetch=old}
});
test('Mistral adapter uses only official endpoint and preserves bounded history',async()=>{
  const old=globalThis.fetch;
  try{
    globalThis.fetch=async (url,init)=>{
      assert.equal(url,'https://api.mistral.ai/v1/chat/completions');
      assert.equal(init.headers.authorization,'Bearer TEST_MISTRAL_KEY');
      assert.deepEqual(JSON.parse(init.body).messages.map(x=>x.role),['system','user']);
      return {ok:true,json:async()=>({choices:[{message:{content:'Known facts only'}}]})};
    };
    assert.equal(await generate({PROVIDER:'mistral',MISTRAL_API_KEY:'TEST_MISTRAL_KEY',MISTRAL_MODEL:'mistral-small-latest'},'system',[{role:'user',content:'Test'}]),'Known facts only');
  }finally{globalThis.fetch=old}
});
test('provider error bodies never expose remote response, token, or untrusted HTML',async()=>{
  const old=globalThis.fetch;
  try{
    globalThis.fetch=async()=>({ok:false,status:403,json:async()=>({key:'SECRET'})});
    await assert.rejects(generate({PROVIDER:'mistral',MISTRAL_API_KEY:'TEST',MISTRAL_MODEL:'model'},'sys',[]),e=>{assert.equal(e.message,'Mistral provider request failed: HTTP 403');return true;});
  }finally{globalThis.fetch=old}
});
