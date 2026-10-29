import { getOnHand, postMovement } from "./ledger.mjs";

const SCALE = 1000;
function fail(message) { throw new TypeError(message); }
function text(value, field) {
  if (typeof value !== "string" || !value.trim()) fail(field + " is required.");
  return value.trim();
}
function qty(value) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0 ||
      Math.abs(value * SCALE - Math.round(value * SCALE)) > 1e-7) {
    fail("Quantity must be positive with at most three decimal places.");
  }
  return Math.round(value * SCALE) / SCALE;
}
function same(a, b) { return JSON.stringify(a) === JSON.stringify(b); }

export function createReservationState() {
  return { events: [] };
}

export function getReservedQuantity(state, productId, locationId) {
  const active = new Map();
  for (const event of state.events) {
    if (event.productId !== productId || event.locationId !== locationId) continue;
    if (event.type === "reserve") active.set(event.reservationId, event.quantity);
    if (event.type === "release" || event.type === "commit") active.delete(event.reservationId);
  }
  return [...active.values()].reduce((sum, value) => sum + value, 0);
}

export function reserveStock(state, ledger, raw) {
  const reservation = {
    type: "reserve",
    id: text(raw.id, "id"),
    idempotencyKey: text(raw.idempotencyKey, "idempotencyKey"),
    reservationId: text(raw.reservationId, "reservationId"),
    productId: text(raw.productId, "productId"),
    locationId: text(raw.locationId, "locationId"),
    quantity: qty(raw.quantity),
    occurredAt: text(raw.occurredAt, "occurredAt"),
    reference: raw.reference == null ? null : String(raw.reference),
  };
  if (!ledger.products[reservation.productId]) fail("Unknown product: " + reservation.productId + ".");
  if (!ledger.locations.includes(reservation.locationId)) fail("Unknown location: " + reservation.locationId + ".");
  const existing = state.events.find((event) => event.idempotencyKey === reservation.idempotencyKey);
  if (existing) {
    if (same(existing, reservation)) return { state, reserved: false, duplicate: true, event: existing };
    fail("Idempotency conflict for reservation key: " + reservation.idempotencyKey + ".");
  }
  if (state.events.some((event) => event.id === reservation.id)) fail("Duplicate reservation event id.");
  if (state.events.some((event) => event.reservationId === reservation.reservationId)) fail("Reservation id already exists.");
  const available = getOnHand(ledger, reservation.productId, reservation.locationId)
    - getReservedQuantity(state, reservation.productId, reservation.locationId);
  if (available + 1e-9 < reservation.quantity) fail("Insufficient available stock for reservation.");
  return { state: { events: [...state.events, reservation] }, reserved: true, duplicate: false, event: reservation };
}

export function resolveReservation(state, ledger, raw) {
  const action = raw.action;
  if (action !== "release" && action !== "commit") fail("Reservation action must be release or commit.");
  const reservation = [...state.events].reverse().find((event) =>
    event.reservationId === raw.reservationId && event.type === "reserve");
  if (!reservation) fail("Unknown reservation id: " + raw.reservationId + ".");
  const event = {
    type: action,
    id: text(raw.id, "id"),
    idempotencyKey: text(raw.idempotencyKey, "idempotencyKey"),
    reservationId: reservation.reservationId,
    productId: reservation.productId,
    locationId: reservation.locationId,
    quantity: reservation.quantity,
    occurredAt: text(raw.occurredAt, "occurredAt"),
  };
  const existing = state.events.find((item) => item.idempotencyKey === event.idempotencyKey);
  if (existing) {
    if (same(existing, event)) return { state, ledger, resolved: false, duplicate: true, event: existing };
    fail("Idempotency conflict for reservation resolution key.");
  }
  if (state.events.some((item) => item.reservationId === reservation.reservationId &&
      (item.type === "release" || item.type === "commit"))) fail("Reservation is already resolved.");
  if (state.events.some((item) => item.id === event.id)) fail("Duplicate reservation event id.");
  let nextLedger = ledger;
  let movement = null;
  if (action === "commit") {
    movement = {
      id: text(raw.movementId, "movementId"),
      idempotencyKey: text(raw.movementIdempotencyKey, "movementIdempotencyKey"),
      type: "issue",
      productId: reservation.productId,
      unit: ledger.products[reservation.productId].unit,
      quantity: reservation.quantity,
      occurredAt: event.occurredAt,
      locationId: reservation.locationId,
      reference: "Reservation " + reservation.reservationId,
    };
    nextLedger = postMovement(ledger, movement).state;
  }
  return {
    state: { events: [...state.events, event] },
    ledger: nextLedger,
    resolved: true,
    duplicate: false,
    event,
    movement,
  };
}

export function createStocktakeSession(ledger, { id, locationId, startedAt }) {
  text(id, "id"); text(startedAt, "startedAt");
  if (!ledger.locations.includes(locationId)) fail("Unknown location: " + locationId + ".");
  const expected = Object.create(null);
  for (const productId of Object.keys(ledger.products)) expected[productId] = getOnHand(ledger, productId, locationId);
  return { id, locationId, startedAt, baseEventCount: ledger.events.length, expected, counts: {} };
}

export function recordStocktakeCount(session, { productId, countedQuantity }) {
  if (!(productId in session.expected)) fail("Product is not part of this stocktake.");
  if (Object.prototype.hasOwnProperty.call(session.counts, productId)) fail("Product already counted in this stocktake.");
  if (typeof countedQuantity !== "number" || !Number.isFinite(countedQuantity) || countedQuantity < 0 ||
      Math.abs(countedQuantity * SCALE - Math.round(countedQuantity * SCALE)) > 1e-7) {
    fail("Counted quantity must be zero or positive with at most three decimal places.");
  }
  return { ...session, counts: { ...session.counts, [productId]: Math.round(countedQuantity * SCALE) / SCALE } };
}

export function finalizeStocktake(session, ledger, { occurredAt, idPrefix, idempotencyPrefix }) {
  if (ledger.events.length !== session.baseEventCount) {
    fail("Stocktake is stale because stock movements occurred during the count; reconcile and recount.");
  }
  const missing = Object.keys(session.expected).filter((productId) => !(productId in session.counts));
  if (missing.length) fail("Stocktake is incomplete; missing counts for: " + missing.join(", ") + ".");
  let state = ledger;
  const adjustments = [];
  for (const productId of Object.keys(session.expected)) {
    const delta = Math.round((session.counts[productId] - session.expected[productId]) * SCALE) / SCALE;
    if (delta === 0) continue;
    const movement = {
      id: idPrefix + "-" + productId,
      idempotencyKey: idempotencyPrefix + "-" + productId,
      type: "adjustment",
      productId,
      unit: state.products[productId].unit,
      quantity: delta,
      occurredAt: text(occurredAt, "occurredAt"),
      locationId: session.locationId,
      reference: "Stocktake " + session.id,
    };
    state = postMovement(state, movement).state;
    adjustments.push(movement);
  }
  return { state, adjustments, sessionId: session.id, reconciled: true };
}

