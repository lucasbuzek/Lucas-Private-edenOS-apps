import test from "node:test";
import assert from "node:assert/strict";
import { addProduct, addLocation, validateCatalogue } from "../src/domain/catalogue.mjs";
import { createLedgerState, postMovement, getOnHand } from "../src/domain/ledger.mjs";

const original = () => {
  const catalogue = [{ id: "EGG-001", name: "Eggs", unit: "each", barcode: "0123", reorderPoint: 8 }];
  const ledger = createLedgerState({ products: catalogue, locations: ["farm"] });
  return { ledger, catalogue };
};

test("catalogue adds product without rewriting original ledger", () => {
  const { ledger, catalogue } = original();
  const result = addProduct(ledger, catalogue, { id: "CHICKEN-002", name: "Chicken", unit: "each", reorderPoint: "4" });
  assert.equal(Object.keys(result.ledger.products).length, 2);
  assert.equal(Object.keys(ledger.products).length, 1);
  assert.equal(result.catalogue[1].reorderPoint, 4);
});
test("catalogue rejects duplicate SKU regardless of case", () => {
  const { ledger, catalogue } = original();
  assert.throws(() => addProduct(ledger, catalogue, { id: "egg-001", name: "Duplicate", unit: "each" }), /Duplicate SKU/);
});
test("catalogue rejects duplicate barcode", () => {
  const { ledger, catalogue } = original();
  assert.throws(() => addProduct(ledger, catalogue, { id: "OTHER", name: "Other", unit: "each", barcode: "0123" }), /Duplicate barcode/);
});
test("invalid reorder thresholds are rejected", () => {
  const { ledger, catalogue } = original();
  for (const bad of [-1, NaN, "invalid", 1.0001]) {
    assert.throws(() => addProduct(ledger, catalogue, { id: "OTHER", name: "Other", unit: "each", reorderPoint: bad }), /Reorder threshold/);
  }
});
test("new location preserves append-only event history", () => {
  const { ledger, catalogue } = original();
  const event = { id: "receipt-1", idempotencyKey: "receipt-1", type: "receipt", productId: "EGG-001", unit: "each", quantity: 12, locationId: "farm", reference: "fixture", occurredAt: "2026-10-11T08:00:00Z" };
  const posted = postMovement(ledger, event).state;
  const result = addLocation(posted, catalogue, "market");
  assert.equal(getOnHand(result.ledger, "EGG-001", "farm"), 12);
  assert.equal(result.ledger.events.length, 1);
  assert.equal(result.ledger.locations.length, 2);
});
test("duplicate locations are rejected case-insensitively", () => {
  const { ledger, catalogue } = original();
  assert.throws(() => addLocation(ledger, catalogue, "FARM"), /Duplicate location/);
});
test("catalogue-ledger mismatch is rejected on restore", () => {
  const { ledger } = original();
  assert.throws(() => validateCatalogue([], ledger), /missing a ledger product/);
  assert.throws(() => validateCatalogue([{ id: "EGG-001", name: "Wrong", unit: "each" }], ledger), /disagree/);
});
