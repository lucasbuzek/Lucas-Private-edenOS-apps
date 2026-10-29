import test from "node:test";
import assert from "node:assert/strict";
import { createLedgerState } from "../src/domain/ledger.mjs";
import { parseCSV, previewCatalogueCSV, applyCatalogueCSV } from "../src/domain/csv-import.mjs";

const sample = "sku,name,unit,barcode,category,reorderPoint\nEGG-1,Eggs,each,123,Food,10\n";
test("CSV parser supports embedded commas, newlines and escaped quotes",()=>{
  const rows=parseCSV('sku,name,unit\nEGG-1,"Eggs, large",each\nEGG-2,"Quote ""test""\ncontinued",each\n');
  assert.deepEqual(rows[1],["EGG-1","Eggs, large","each"]);
  assert.equal(rows[2][1],'Quote "test"\ncontinued');
});
test("CSV dry run validates without changing ledger or catalogue",()=>{
  const initial=createLedgerState({locations:["shop"]});
  const preview=previewCatalogueCSV([],sample);
  assert.equal(preview.canCommit,true);
  assert.equal(preview.products.length,1);
  assert.equal(Object.keys(initial.products).length,0);
  const applied=applyCatalogueCSV(initial,[],preview);
  assert.equal(applied.catalogue[0].id,"EGG-1");
  assert.equal(applied.ledger.events.length,0);
  assert.equal(initial.events.length,0);
});
test("CSV rejects duplicate SKU in same import",()=>{
  const p=previewCatalogueCSV([],sample+"EGG-1,Again,each,124,Food,8\n");
  assert.equal(p.canCommit,false);
  assert.match(p.errors[0].message,/Duplicate SKU/);
});
test("CSV rejects duplicate barcode against current catalogue",()=>{
  const p=previewCatalogueCSV([{id:"EXIST",name:"Other",unit:"each",barcode:"123"}],sample);
  assert.equal(p.canCommit,false);
  assert.match(p.errors[0].message,/Duplicate barcode/);
});
test("CSV rejects malformed quoting and unknown columns",()=>{
  assert.throws(()=>parseCSV('a,"unterminated'),/unterminated/);
  assert.throws(()=>previewCatalogueCSV([],"sku,name,unit,quantity\nA,B,each,1"),/Unsupported CSV column/);
});
test("CSV returns row-specific errors without partial commit",()=>{
  const p=previewCatalogueCSV([],"sku,name,unit\nGOOD,Good,each\nBAD,,each\n");
  assert.equal(p.products.length,1);
  assert.equal(p.errors.length,1);
  assert.equal(p.errors[0].line,3);
  assert.throws(()=>applyCatalogueCSV(createLedgerState(),[],p),/dry-run/);
});
