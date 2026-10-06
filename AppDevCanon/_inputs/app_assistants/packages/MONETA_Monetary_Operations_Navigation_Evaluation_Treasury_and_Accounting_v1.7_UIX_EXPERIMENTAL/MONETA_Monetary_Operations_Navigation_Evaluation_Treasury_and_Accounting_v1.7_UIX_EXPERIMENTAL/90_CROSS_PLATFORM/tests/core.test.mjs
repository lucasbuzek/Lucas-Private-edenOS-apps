import test from"node:test";import assert from"node:assert/strict";import{registry,route,resourceProfile}from"../core/moneta-core.mjs";
test("9 companies",()=>assert.equal(registry.companies.length,9));
test("59 capabilities",()=>assert.equal(registry.capabilities.length,59));
test("budget to ALLOCATE",()=>assert.equal(route("authoritative tender budget").owner,"ALLOCATE"));
test("tender discovery stays HERMES",()=>assert.equal(route("discover tender opportunity").application,"HERMES"));
test("full profile",()=>assert.equal(resourceProfile({memoryGB:16,cores:8}).profile,"FULL"));
test("lean profile",()=>assert.equal(resourceProfile({memoryGB:4,cores:2}).profile,"LEAN"));