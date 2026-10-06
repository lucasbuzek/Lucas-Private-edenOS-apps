import test from"node:test";import assert from"node:assert/strict";import fs from"node:fs";
const h=fs.readFileSync("web/index.html","utf8");
test("LCAS visible",()=>assert.match(h,/LCAS · Active · Experimental/));
test("Simple Advanced Expert",()=>{for(const x of ["simple","advanced","expert"])assert.match(h,new RegExp(`data-depth="${x}"`))});
test("mobile domain navigation",()=>assert.match(h,/Overview<\/button><button>Companies<\/button><button>Work<\/button><button>Status/));
test("safety state visible",()=>assert.match(h,/Money movement, bank changes, journal posting, tax filing and external reporting remain disabled/));
test("inspector present",()=>assert.match(h,/>Inspector</));
test("domain companies direct",()=>assert.match(h,/Finance companies/));