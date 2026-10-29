import test from "node:test";
import assert from "node:assert/strict";
import { answerInventoryQuery, searchProducts } from "../src/domain/queries.mjs";
import { demoCatalogue, demoLedgerState, demoProvenance } from "../fixtures/demo-inventory.mjs";

const query = (overrides = {}) => ({
  state: demoLedgerState,
  catalogue: demoCatalogue,
  provenance: demoProvenance,
  intent: "stock",
  query: "SKU-TEA-001",
  ...overrides,
});

test("fixture search matches product name, SKU and barcode", () => {
  assert.equal(searchProducts(demoCatalogue, "black tea").length, 1);
  assert.equal(searchProducts(demoCatalogue, "SKU-TEA-001")[0].name, "Black tea 100 bags");
  assert.equal(searchProducts(demoCatalogue, "6001000000029")[0].id, "SKU-RICE-002");
});

test("stock answer totals locations and labels fixture provenance and read-only state", () => {
  const answer = answerInventoryQuery(query());
  assert.equal(answer.status, "OK");
  assert.equal(answer.onHand, 10);
  assert.equal(answer.byLocation["shop-floor"], 6);
  assert.equal(answer.byLocation["back-store"], 4);
  assert.equal(answer.source.kind, "fixture");
  assert.equal(answer.readOnly, true);
  assert.equal(answer.externalWrites, "DISABLED");
});

test("low-stock query returns only catalogue items at or below reorder point", () => {
  const answer = answerInventoryQuery(query({ intent: "low-stock", query: "" }));
  assert.deepEqual(answer.items.map((row) => row.product.id).sort(), ["SKU-RICE-002", "SKU-SOAP-003"]);
});

test("stock query does not invent available, reserved or incoming quantities", () => {
  const answer = answerInventoryQuery(query());
  assert.equal(answer.reserved.status, "UNKNOWN");
  assert.equal(answer.available.status, "UNKNOWN");
  assert.equal(answer.incoming.status, "UNKNOWN");
});

test("ambiguous search requires product selection instead of guessing", () => {
  const answer = answerInventoryQuery(query({ query: "60010000000" }));
  assert.equal(answer.status, "NEEDS_SELECTION");
  assert.equal(answer.matches.length, 3);
});

test("movement history is read-only and reports only matching product events", () => {
  const answer = answerInventoryQuery(query({ intent: "movement-history" }));
  assert.equal(answer.events.length, 2);
  assert.ok(answer.events.every((event) => event.productId === "SKU-TEA-001"));
});

test("missing provenance is rejected and unsupported intent stays explicit", () => {
  assert.throws(() => answerInventoryQuery(query({ provenance: null })), /provenance/i);
  assert.equal(answerInventoryQuery(query({ intent: "post-stock" })).status, "UNSUPPORTED_INTENT");
});

