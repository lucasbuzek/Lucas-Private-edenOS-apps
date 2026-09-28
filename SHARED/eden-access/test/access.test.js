import test from "node:test";
import assert from "node:assert/strict";
import {localProfile,personalize,requiresNetworkAuth} from "../src/index.js";

test("local profile requires no account",()=>{
 const m=new Map(); const s={getItem:k=>m.get(k)||null,setItem:(k,v)=>m.set(k,v)};
 const p=localProfile(s); assert.equal(p.mode,"local"); assert.equal(p.identity,null);
});
test("sign-in personalizes existing profile",()=>{
 const p={id:"local-1",mode:"local",identity:null};
 const q=personalize(p,{provider:"apple",subject:"abc"});
 assert.equal(q.id,"local-1"); assert.equal(q.mode,"personalized");
});
test("network protected routes require auth",()=>{
 assert.equal(requiresNetworkAuth("/api/me"),true);
 assert.equal(requiresNetworkAuth("/index.html"),false);
});
