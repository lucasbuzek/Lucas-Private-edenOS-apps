import test from "node:test";
import assert from "node:assert/strict";
import { createLedgerState, getOnHand, getStockSummary, postMovement, createReversal } from "../src/domain/ledger.mjs";

const initial = () => createLedgerState({
  products: [{ id: "SKU-1", name: "Sample bolt", unit: "each" }],
  locations: ["shop", "warehouse"],
});
const movement = (overrides = {}) => ({
  id: "m-1", idempotencyKey: "idem-1", type: "receipt", productId: "SKU-1",
  unit: "each", quantity: 10, occurredAt: "2026-10-11T10:00:00Z", locationId: "shop",
  ...overrides,
});

test("receipt and issue calculate on-hand stock", () => {
  let state = initial();
  state = postMovement(state, movement()).state;
  state = postMovement(state, movement({ id: "m-2", idempotencyKey: "idem-2", type: "issue", quantity: 2 })).state;
  assert.equal(getOnHand(state, "SKU-1", "shop"), 8);
});

test("transfer moves stock between locations without changing total", () => {
  let state = postMovement(initial(), movement()).state;
  state = postMovement(state, movement({
    id: "m-2", idempotencyKey: "idem-2", type: "transfer", quantity: 4,
    locationId: undefined, fromLocationId: "shop", toLocationId: "warehouse",
  })).state;
  assert.equal(getOnHand(state, "SKU-1", "shop"), 6);
  assert.equal(getOnHand(state, "SKU-1", "warehouse"), 4);
  assert.equal(getStockSummary(state, "SKU-1").total, 10);
});

test("same idempotency key and payload is safe to retry", () => {
  let state = postMovement(initial(), movement()).state;
  const retry = postMovement(state, movement());
  assert.equal(retry.duplicate, true);
  assert.equal(retry.state.events.length, 1);
});

test("same idempotency key with changed payload is rejected", () => {
  const state = postMovement(initial(), movement()).state;
  assert.throws(() => postMovement(state, movement({ quantity: 11 })), /Idempotency conflict/);
});

test("insufficient stock issue is rejected", () => {
  assert.throws(() => postMovement(initial(), movement({
    id: "m-2", idempotencyKey: "idem-2", type: "issue", quantity: 1,
  })), /Insufficient stock/);
});

test("unit mismatch and unknown location are rejected", () => {
  assert.throws(() => postMovement(initial(), movement({ unit: "kg" })), /Unit mismatch/);
  assert.throws(() => postMovement(initial(), movement({ locationId: "unknown" })), /Unknown location/);
});

test("fractional quantities are exact to three decimal places", () => {
  let state = postMovement(initial(), movement({ quantity: 1.125 })).state;
  state = postMovement(state, movement({
    id: "m-2", idempotencyKey: "idem-2", type: "issue", quantity: 0.125,
  })).state;
  assert.equal(getOnHand(state, "SKU-1", "shop"), 1);
  assert.throws(() => postMovement(state, movement({ id: "m-3", idempotencyKey: "idem-3", quantity: 0.0001 })), /three decimal places/);
});

test("reversal is an explicit compensating event", () => {
  let state = postMovement(initial(), movement()).state;
  const reversal = createReversal(state, "m-1", {
    id: "m-reversal", idempotencyKey: "idem-reversal", occurredAt: "2026-10-11T11:00:00Z",
  });
  state = postMovement(state, reversal).state;
  assert.equal(getOnHand(state, "SKU-1", "shop"), 0);
  assert.equal(state.events.length, 2);
});

test("movement ids are unique", () => {
  const state = postMovement(initial(), movement()).state;
  assert.throws(() => postMovement(state, movement({ idempotencyKey: "idem-2" })), /Duplicate movement id/);
});


test("negative adjustment cannot drive stock below zero", () => {
  const state = postMovement(initial(), movement()).state;
  assert.throws(() => postMovement(state, movement({
    id: "m-adjust", idempotencyKey: "idem-adjust", type: "adjustment", quantity: -11,
  })), /Insufficient stock/);
});

test("zero adjustment and same-location transfer are rejected", () => {
  assert.throws(() => postMovement(initial(), movement({
    type: "adjustment", quantity: 0,
  })), /must not be zero/);
  assert.throws(() => postMovement(initial(), movement({
    type: "transfer", locationId: undefined, fromLocationId: "shop", toLocationId: "shop",
  })), /must differ/);
});

test("transfer cannot make source stock negative", () => {
  assert.throws(() => postMovement(initial(), movement({
    type: "transfer", locationId: undefined, fromLocationId: "shop", toLocationId: "warehouse",
  })), /Insufficient stock/);
});

test("posted events are append-only and original state remains unchanged", () => {
  const before = initial();
  const after = postMovement(before, movement()).state;
  assert.equal(before.events.length, 0);
  assert.equal(after.events.length, 1);
  assert.notEqual(before, after);
});