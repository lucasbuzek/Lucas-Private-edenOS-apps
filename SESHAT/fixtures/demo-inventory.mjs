/**
 * DEMONSTRATION FIXTURE ONLY.
 * These products and movements are fabricated test data, not a live business inventory.
 */
import { createLedgerState, postMovement } from "../src/domain/ledger.mjs";

export const demoProvenance = Object.freeze({
  label: "SESHAT demonstration fixture",
  kind: "fixture",
  asOf: "2026-10-11T00:00:00Z",
});

export const demoCatalogue = Object.freeze([
  { id: "SKU-TEA-001", name: "Black tea 100 bags", barcode: "6001000000012", category: "Beverages", unit: "pack", reorderPoint: 8 },
  { id: "SKU-RICE-002", name: "Rice 2 kg", barcode: "6001000000029", category: "Staples", unit: "bag", reorderPoint: 10 },
  { id: "SKU-SOAP-003", name: "Laundry soap bar", barcode: "6001000000036", category: "Household", unit: "bar", reorderPoint: 5 },
]);

let state = createLedgerState({
  products: demoCatalogue.map(({ id, name, unit }) => ({ id, name, unit })),
  locations: ["shop-floor", "back-store"],
});
const events = [
  { id: "demo-evt-1", idempotencyKey: "demo-idem-1", type: "receipt", productId: "SKU-TEA-001", unit: "pack", quantity: 6, occurredAt: "2026-10-10T08:00:00Z", locationId: "shop-floor", reference: "DEMO-DELIVERY-1" },
  { id: "demo-evt-2", idempotencyKey: "demo-idem-2", type: "receipt", productId: "SKU-TEA-001", unit: "pack", quantity: 4, occurredAt: "2026-10-10T08:05:00Z", locationId: "back-store", reference: "DEMO-DELIVERY-1" },
  { id: "demo-evt-3", idempotencyKey: "demo-idem-3", type: "receipt", productId: "SKU-RICE-002", unit: "bag", quantity: 7, occurredAt: "2026-10-10T08:10:00Z", locationId: "shop-floor", reference: "DEMO-DELIVERY-2" },
  { id: "demo-evt-4", idempotencyKey: "demo-idem-4", type: "receipt", productId: "SKU-SOAP-003", unit: "bar", quantity: 9, occurredAt: "2026-10-10T08:15:00Z", locationId: "shop-floor", reference: "DEMO-DELIVERY-3" },
  { id: "demo-evt-5", idempotencyKey: "demo-idem-5", type: "issue", productId: "SKU-SOAP-003", unit: "bar", quantity: 5, occurredAt: "2026-10-10T12:00:00Z", locationId: "shop-floor", reference: "DEMO-SALE-1" },
];
for (const event of events) state = postMovement(state, event).state;

export const demoLedgerState = state;

