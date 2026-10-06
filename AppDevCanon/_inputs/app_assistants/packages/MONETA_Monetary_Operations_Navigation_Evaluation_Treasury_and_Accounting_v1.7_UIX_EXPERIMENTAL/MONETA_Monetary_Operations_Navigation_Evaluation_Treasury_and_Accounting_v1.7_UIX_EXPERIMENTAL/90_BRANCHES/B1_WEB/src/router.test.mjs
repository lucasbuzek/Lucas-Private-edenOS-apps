import test from "node:test";import assert from "node:assert/strict";import {routeCapability} from "./router.mjs";
test("receipt routes MONETA RECEIPT",()=>assert.equal(routeCapability({objective:"process receipt"}).owner,"RECEIPT"));
test("treasury routes MONETA VAULT",()=>assert.equal(routeCapability({objective:"cash treasury"}).owner,"VAULT"));
test("tender discovery stays HERMES",()=>assert.equal(routeCapability({objective:"discover tender opportunities"}).application,"HERMES"));
test("tender budget is MONETA ALLOCATE",()=>assert.equal(routeCapability({objective:"authoritative tender budget"}).owner,"ALLOCATE"));
test("bid profitability is MONETA MARGIN",()=>assert.equal(routeCapability({objective:"bid profitability"}).owner,"MARGIN"));
test("tax is MONETA TRIBUTE",()=>assert.equal(routeCapability({objective:"tax evidence"}).owner,"TRIBUTE"));
test("fallback MONETA",()=>assert.equal(routeCapability({objective:"finance"}).owner,"MONETA"));
