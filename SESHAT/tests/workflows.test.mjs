import test from "node:test";
import assert from "node:assert/strict";
import { createLedgerState, postMovement, getOnHand } from "../src/domain/ledger.mjs";
import {
  createReservationState, getReservedQuantity, reserveStock, resolveReservation,
  createStocktakeSession, recordStocktakeCount, finalizeStocktake,
} from "../src/domain/workflows.mjs";

function seed() {
  let ledger = createLedgerState({
    products: [{ id: "A", name: "Sample item", unit: "each" }, { id: "B", name: "Second item", unit: "box" }],
    locations: ["shop"],
  });
  ledger = postMovement(ledger, { id: "receipt-a", idempotencyKey: "receipt-a", type: "receipt", productId: "A", unit: "each", quantity: 10, occurredAt: "2026-10-11T08:00:00Z", locationId: "shop" }).state;
  ledger = postMovement(ledger, { id: "receipt-b", idempotencyKey: "receipt-b", type: "receipt", productId: "B", unit: "box", quantity: 4, occurredAt: "2026-10-11T08:00:00Z", locationId: "shop" }).state;
  return ledger;
}
const reservation = (overrides = {}) => ({
  id: "res-event-1", idempotencyKey: "res-idem-1", reservationId: "order-1",
  productId: "A", locationId: "shop", quantity: 6, occurredAt: "2026-10-11T09:00:00Z", ...overrides,
});

test("reservation reduces available-to-reserve quantity without changing ledger on-hand", () => {
  const ledger = seed();
  const result = reserveStock(createReservationState(), ledger, reservation());
  assert.equal(getReservedQuantity(result.state, "A", "shop"), 6);
  assert.equal(getOnHand(ledger, "A", "shop"), 10);
});

test("reservations cannot exceed unreserved stock", () => {
  let state = reserveStock(createReservationState(), seed(), reservation()).state;
  assert.throws(() => reserveStock(state, seed(), reservation({
    id: "res-event-2", idempotencyKey: "res-idem-2", reservationId: "order-2", quantity: 5,
  })), /Insufficient available stock/);
});

test("reservation retry is idempotent and conflicting retry is rejected", () => {
  const ledger = seed();
  const first = reserveStock(createReservationState(), ledger, reservation());
  assert.equal(reserveStock(first.state, ledger, reservation()).duplicate, true);
  assert.throws(() => reserveStock(first.state, ledger, reservation({ quantity: 5 })), /Idempotency conflict/);
});

test("release frees reserved stock without posting ledger movement", () => {
  const ledger = seed();
  const held = reserveStock(createReservationState(), ledger, reservation());
  const released = resolveReservation(held.state, ledger, {
    action: "release", id: "res-release", idempotencyKey: "res-release-key", reservationId: "order-1", occurredAt: "2026-10-11T09:30:00Z",
  });
  assert.equal(getReservedQuantity(released.state, "A", "shop"), 0);
  assert.equal(released.ledger.events.length, ledger.events.length);
});

test("commit posts one issue movement and resolves reservation", () => {
  const ledger = seed();
  const held = reserveStock(createReservationState(), ledger, reservation());
  const committed = resolveReservation(held.state, ledger, {
    action: "commit", id: "res-commit", idempotencyKey: "res-commit-key", reservationId: "order-1",
    occurredAt: "2026-10-11T10:00:00Z", movementId: "issue-order-1", movementIdempotencyKey: "issue-order-1-key",
  });
  assert.equal(getOnHand(committed.ledger, "A", "shop"), 4);
  assert.equal(getReservedQuantity(committed.state, "A", "shop"), 0);
  assert.equal(committed.ledger.events.length, ledger.events.length + 1);
});

test("resolution retry is idempotent after a reservation has been resolved", () => {
  const ledger = seed();
  const held = reserveStock(createReservationState(), ledger, reservation());
  const payload = {
    action: "release", id: "res-release", idempotencyKey: "res-release-key",
    reservationId: "order-1", occurredAt: "2026-10-11T09:30:00Z",
  };
  const first = resolveReservation(held.state, ledger, payload);
  const retry = resolveReservation(first.state, first.ledger, payload);
  assert.equal(retry.duplicate, true);
  assert.equal(retry.state.events.length, first.state.events.length);
});

test("unknown and already resolved reservations are rejected", () => {
  const ledger = seed();
  assert.throws(() => resolveReservation(createReservationState(), ledger, {
    action: "release", id: "x", idempotencyKey: "x", reservationId: "missing", occurredAt: "2026-10-11T09:30:00Z",
  }), /Unknown reservation/);
  const held = reserveStock(createReservationState(), ledger, reservation());
  const released = resolveReservation(held.state, ledger, {
    action: "release", id: "res-release", idempotencyKey: "res-release-key", reservationId: "order-1", occurredAt: "2026-10-11T09:30:00Z",
  });
  assert.throws(() => resolveReservation(released.state, ledger, {
    action: "commit", id: "res-commit", idempotencyKey: "res-commit-key", reservationId: "order-1",
    occurredAt: "2026-10-11T10:00:00Z", movementId: "issue-order-1", movementIdempotencyKey: "issue-order-1-key",
  }), /already resolved/);
});

test("stocktake records counts and posts compensating adjustments", () => {
  const ledger = seed();
  let session = createStocktakeSession(ledger, { id: "count-1", locationId: "shop", startedAt: "2026-10-11T11:00:00Z" });
  session = recordStocktakeCount(session, { productId: "A", countedQuantity: 8 });
  session = recordStocktakeCount(session, { productId: "B", countedQuantity: 5 });
  const result = finalizeStocktake(session, ledger, {
    occurredAt: "2026-10-11T11:30:00Z", idPrefix: "count-adjust", idempotencyPrefix: "count-adjust-key",
  });
  assert.equal(result.adjustments.length, 2);
  assert.equal(getOnHand(result.state, "A", "shop"), 8);
  assert.equal(getOnHand(result.state, "B", "shop"), 5);
});

test("stocktake cannot finalize with missing counts or duplicate count lines", () => {
  const ledger = seed();
  let session = createStocktakeSession(ledger, { id: "count-2", locationId: "shop", startedAt: "2026-10-11T11:00:00Z" });
  session = recordStocktakeCount(session, { productId: "A", countedQuantity: 10 });
  assert.throws(() => recordStocktakeCount(session, { productId: "A", countedQuantity: 9 }), /already counted/);
  assert.throws(() => finalizeStocktake(session, ledger, {
    occurredAt: "2026-10-11T11:30:00Z", idPrefix: "x", idempotencyPrefix: "x",
  }), /incomplete/);
});

test("stocktake refuses stale counts after any concurrent movement", () => {
  const ledger = seed();
  let session = createStocktakeSession(ledger, { id: "count-3", locationId: "shop", startedAt: "2026-10-11T11:00:00Z" });
  session = recordStocktakeCount(session, { productId: "A", countedQuantity: 10 });
  session = recordStocktakeCount(session, { productId: "B", countedQuantity: 4 });
  const changed = postMovement(ledger, { id: "new-issue", idempotencyKey: "new-issue", type: "issue", productId: "A", unit: "each", quantity: 1, occurredAt: "2026-10-11T11:10:00Z", locationId: "shop" }).state;
  assert.throws(() => finalizeStocktake(session, changed, {
    occurredAt: "2026-10-11T11:30:00Z", idPrefix: "x", idempotencyPrefix: "x",
  }), /stale/);
});

test("stocktake allows a true zero count and rejects invalid count quantities", () => {
  const ledger = seed();
  let session = createStocktakeSession(ledger, { id: "count-4", locationId: "shop", startedAt: "2026-10-11T11:00:00Z" });
  assert.throws(() => recordStocktakeCount(session, { productId: "A", countedQuantity: -1 }), /Counted quantity/);
  session = recordStocktakeCount(session, { productId: "A", countedQuantity: 0 });
  session = recordStocktakeCount(session, { productId: "B", countedQuantity: 4 });
  const result = finalizeStocktake(session, ledger, {
    occurredAt: "2026-10-11T11:30:00Z", idPrefix: "zero-count", idempotencyPrefix: "zero-count-key",
  });
  assert.equal(getOnHand(result.state, "A", "shop"), 0);
});

