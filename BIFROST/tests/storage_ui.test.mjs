import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
const source = readFileSync(new URL('../headless/dashboard.js', import.meta.url),'utf8').split('// Storage uses the existing profile-bound backend and session; never a raw path.')[1];
function harness(request) {
  const nodes = new Map();
  const $ = id => { if (!nodes.has(id)) nodes.set(id,{value:'',textContent:'',children:[],replaceChildren(){this.children=[];},append(x){this.children.push(x);},addEventListener(){}}); return nodes.get(id); };
  const context = vm.createContext({$, token:'session',request,document:{createElement:()=>({})}});
  vm.runInContext(source,context);
  $('storageProfile').value='approved';
  return {context,$};
}
test('local preview never opts into remote reads and renders names as text',async()=>{
 let payload;
 const {context,$}=harness(async(path,p)=>{assert.equal(path,'/api/storage/v1/preview');payload=p;return {status:'LOCAL_READ_ONLY',count:1,entries:[{name:'<script>',kind:'file',bytes:1}]};});
 await vm.runInContext('browseStorage(false)',context);
 assert.equal(payload.readRemote,false);
 assert.equal($('storageResults').children[0].textContent,'<script> · file · 1 bytes');
});
test('selection invalidation prevents late results from repopulating UI',async()=>{
 let resolve;const {context,$}=harness(()=>new Promise(r=>{resolve=r;}));
 const pending=vm.runInContext('browseStorage(true)',context);
 vm.runInContext('clearStoragePreview()',context);
 resolve({status:'REMOTE_READ_ONLY',count:1,entries:[{name:'old',kind:'file'}]});await pending;
 assert.equal($('storageResults').children.length,0);
 assert.equal($('storageFeedback').textContent,'No current preview.');
});
test('missing session issues no storage request',async()=>{
 const {context,$}=harness(()=>{throw Error('unexpected request');});
 vm.runInContext('token=null',context);await vm.runInContext('browseStorage(true)',context);
 assert.equal($('storageFeedback').textContent,'Connect to Headless first.');
});
