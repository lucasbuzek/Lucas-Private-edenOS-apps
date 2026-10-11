import test from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { createLedgerState, postMovement, getStockSummary } from "../src/domain/ledger.mjs";
import { exportLedgerSnapshot, importLedgerSnapshot } from "../src/persistence/snapshot.mjs";

function seeded() {
  let state = createLedgerState({
    products: [{ id: "SKU-2", name: "Sample washer", unit: "each" }, { id: "SKU-1", name: "Sample bolt", unit: "each" }],
    locations: ["shop", "warehouse"],
  });
  state = postMovement(state, {
    id: "evt-1", idempotencyKey: "idem-1", type: "receipt", productId: "SKU-1",
    unit: "each", quantity: 12.5, occurredAt: "2026-10-11T08:00:00Z", locationId: "shop", reference: "delivery-1",
  }).state;
  state = postMovement(state, {
    id: "evt-2", idempotencyKey: "idem-2", type: "transfer", productId: "SKU-1",
    unit: "each", quantity: 2.25, occurredAt: "2026-10-11T09:00:00Z",
    fromLocationId: "shop", toLocationId: "warehouse", reference: null,
  }).state;
  return state;
}

function stableStringify(value) {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(",")}]`;
  return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`).join(",")}}`;
}

function resign(document) {
  const payload = {
    schemaVersion: document.schemaVersion,
    products: document.products,
    locations: document.locations,
    events: document.events,
  };
  document.checksum = {
    algorithm: "SHA-256",
    value: createHash("sha256").update(stableStringify(payload)).digest("hex"),
  };
  return JSON.stringify(document);
}

test("snapshot round-trip preserves products, locations, events and balances", async () => {
  const original = seeded();
  const restored = await importLedgerSnapshot(await exportLedgerSnapshot(original));
  assert.deepEqual(restored, original);
  assert.deepEqual(getStockSummary(restored, "SKU-1"), getStockSummary(original, "SKU-1"));
});

test("snapshot detects modified data before restore", async () => {
  const document = JSON.parse(await exportLedgerSnapshot(seeded()));
  document.events[0].quantity = 999;
  await assert.rejects(importLedgerSnapshot(JSON.stringify(document)), /checksum mismatch/i);
});

test("snapshot rejects unsupported schema versions", async () => {
  const document = JSON.parse(await exportLedgerSnapshot(seeded()));
  document.schemaVersion = 2;
  await assert.rejects(importLedgerSnapshot(resign(document)), /Unsupported snapshot schema version/);
});

test("snapshot rejects tampered history even when checksum is recomputed", async () => {
  const document = JSON.parse(await exportLedgerSnapshot(seeded()));
  document.events = [{
    id: "evt-issue", idempotencyKey: "idem-issue", type: "issue", productId: "SKU-1",
    unit: "each", quantity: 1, occurredAt: "2026-10-11T07:00:00Z", locationId: "shop", reference: null,
  }];
  await assert.rejects(importLedgerSnapshot(resign(document)), /Insufficient stock/);
});

test("snapshot rejects duplicate location ids even when checksum is valid", async () => {
  const document = JSON.parse(await exportLedgerSnapshot(seeded()));
  document.locations.push("shop");
  await assert.rejects(importLedgerSnapshot(resign(document)), /unique/);
});