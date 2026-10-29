const MOVEMENT_TYPES = new Set(["receipt", "issue", "return", "transfer", "adjustment"]);
const QUANTITY_SCALE = 1000;

function fail(message) {
  throw new TypeError(message);
}

function quantityToUnits(value, { signed = false } = {}) {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    fail("Quantity must be a finite number.");
  }
  if (!signed && value <= 0) fail("Quantity must be greater than zero.");
  const scaled = value * QUANTITY_SCALE;
  if (!Number.isSafeInteger(Math.round(scaled)) || Math.abs(scaled - Math.round(scaled)) > 1e-7) {
    fail("Quantity supports at most three decimal places.");
  }
  return Math.round(scaled);
}

function unitsToQuantity(value) {
  return value / QUANTITY_SCALE;
}

function requireText(value, field) {
  if (typeof value !== "string" || value.trim() === "") fail(`${field} is required.`);
  return value.trim();
}

function normalizeMovement(movement) {
  if (!movement || typeof movement !== "object" || Array.isArray(movement)) {
    fail("Movement must be an object.");
  }
  const type = requireText(movement.type, "type");
  if (!MOVEMENT_TYPES.has(type)) fail(`Unsupported movement type: ${type}.`);
  const normalized = {
    id: requireText(movement.id, "id"),
    idempotencyKey: requireText(movement.idempotencyKey, "idempotencyKey"),
    type,
    productId: requireText(movement.productId, "productId"),
    unit: requireText(movement.unit, "unit"),
    quantity: movement.quantity,
    occurredAt: requireText(movement.occurredAt, "occurredAt"),
    reference: movement.reference == null ? null : String(movement.reference).trim() || null,
  };
  if (Number.isNaN(Date.parse(normalized.occurredAt))) fail("occurredAt must be a valid date/time.");
  quantityToUnits(normalized.quantity, { signed: type === "adjustment" });
  if (type === "adjustment" && normalized.quantity === 0) fail("Adjustment quantity must not be zero.");
  if (type === "transfer") {
    normalized.fromLocationId = requireText(movement.fromLocationId, "fromLocationId");
    normalized.toLocationId = requireText(movement.toLocationId, "toLocationId");
    if (normalized.fromLocationId === normalized.toLocationId) fail("Transfer source and destination must differ.");
  } else {
    normalized.locationId = requireText(movement.locationId, "locationId");
  }
  return normalized;
}

function sameMovement(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

function requireLocation(state, locationId) {
  if (!state.locations.includes(locationId)) fail(`Unknown location: ${locationId}.`);
}

function stockDelta(movement, locationId) {
  const q = quantityToUnits(movement.quantity, { signed: movement.type === "adjustment" });
  if (movement.type === "receipt" || movement.type === "return") {
    return movement.locationId === locationId ? q : 0;
  }
  if (movement.type === "issue") return movement.locationId === locationId ? -q : 0;
  if (movement.type === "adjustment") return movement.locationId === locationId ? q : 0;
  if (movement.type === "transfer") {
    if (movement.fromLocationId === locationId) return -q;
    if (movement.toLocationId === locationId) return q;
  }
  return 0;
}

export function createLedgerState({ products = [], locations = [], events = [] } = {}) {
  const productMap = Object.create(null);
  for (const product of products) {
    const id = requireText(product.id, "product.id");
    if (Object.hasOwn(productMap, id)) fail(`Duplicate product id: ${id}.`);
    productMap[id] = { id, unit: requireText(product.unit, "product.unit"), name: String(product.name ?? id) };
  }
  const locationIds = locations.map((location) => requireText(
    typeof location === "string" ? location : location.id, "location.id"
  ));
  if (new Set(locationIds).size !== locationIds.length) fail("Location ids must be unique.");
  let state = { products: productMap, locations: locationIds, events: [] };
  for (const event of events) state = postMovement(state, event, { allowNegative: true }).state;
  return state;
}

export function getOnHand(state, productId, locationId) {
  if (!state.products[productId]) fail(`Unknown product: ${productId}.`);
  requireLocation(state, locationId);
  let total = 0;
  for (const event of state.events) {
    if (event.productId === productId) total += stockDelta(event, locationId);
  }
  return unitsToQuantity(total);
}

export function getStockSummary(state, productId) {
  if (!state.products[productId]) fail(`Unknown product: ${productId}.`);
  const byLocation = Object.create(null);
  let total = 0;
  for (const locationId of state.locations) {
    const quantity = getOnHand(state, productId, locationId);
    byLocation[locationId] = quantity;
    total += quantityToUnits(quantity, { signed: true });
  }
  return { productId, unit: state.products[productId].unit, byLocation, total: unitsToQuantity(total) };
}

export function postMovement(state, rawMovement, { allowNegative = false } = {}) {
  const movement = normalizeMovement(rawMovement);
  const product = state.products[movement.productId];
  if (!product) fail(`Unknown product: ${movement.productId}.`);
  if (product.unit !== movement.unit) fail(`Unit mismatch for product ${movement.productId}: expected ${product.unit}.`);
  if (movement.type === "transfer") {
    requireLocation(state, movement.fromLocationId);
    requireLocation(state, movement.toLocationId);
  } else {
    requireLocation(state, movement.locationId);
  }

  const existingKey = state.events.find((event) => event.idempotencyKey === movement.idempotencyKey);
  if (existingKey) {
    if (sameMovement(existingKey, movement)) return { state, posted: false, duplicate: true, event: existingKey };
    fail(`Idempotency conflict for key: ${movement.idempotencyKey}.`);
  }
  if (state.events.some((event) => event.id === movement.id)) fail(`Duplicate movement id: ${movement.id}.`);

  if (!allowNegative) {
    const locationsToCheck = movement.type === "transfer"
      ? [movement.fromLocationId]
      : movement.type === "issue" || (movement.type === "adjustment" && movement.quantity < 0)
        ? [movement.locationId] : [];
    for (const locationId of locationsToCheck) {
      const next = getOnHand(state, movement.productId, locationId) + stockDelta(movement, locationId) / QUANTITY_SCALE;
      if (next < -1e-9) fail(`Insufficient stock at ${locationId}; movement would make stock negative.`);
    }
  }

  const nextState = { ...state, events: [...state.events, movement] };
  return { state: nextState, posted: true, duplicate: false, event: movement };
}

export function createReversal(state, movementId, { id, idempotencyKey, occurredAt }) {
  const original = state.events.find((event) => event.id === movementId);
  if (!original) fail(`Unknown movement id: ${movementId}.`);
  const common = {
    id: requireText(id, "id"),
    idempotencyKey: requireText(idempotencyKey, "idempotencyKey"),
    productId: original.productId,
    unit: original.unit,
    quantity: original.quantity,
    occurredAt: requireText(occurredAt, "occurredAt"),
    reference: `Reversal of ${original.id}`,
  };
  if (original.type === "receipt") return { ...common, type: "issue", locationId: original.locationId };
  if (original.type === "issue") return { ...common, type: "receipt", locationId: original.locationId };
  if (original.type === "return") return { ...common, type: "issue", locationId: original.locationId };
  if (original.type === "adjustment") return { ...common, type: "adjustment", quantity: -original.quantity, locationId: original.locationId };
  return { ...common, type: "transfer", fromLocationId: original.toLocationId, toLocationId: original.fromLocationId };
}