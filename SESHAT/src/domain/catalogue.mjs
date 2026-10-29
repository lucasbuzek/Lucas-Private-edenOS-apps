import { createLedgerState } from "./ledger.mjs";

function required(value, label) {
  if (typeof value !== "string" || !value.trim()) throw new TypeError(label + " is required.");
  return value.trim();
}
function uniqueText(value, label) {
  const text = String(value ?? "").trim();
  if (!text) throw new TypeError(label + " is required.");
  return text;
}
export function validateCatalogue(catalogue, ledger) {
  if (!Array.isArray(catalogue)) throw new TypeError("Catalogue must be an array.");
  const ids = new Set(), barcodes = new Set();
  for (const product of catalogue) {
    const id = required(product?.id, "SKU");
    const name = required(product?.name, "Name");
    const unit = required(product?.unit, "Unit");
    if (ids.has(id.toLowerCase())) throw new TypeError("Duplicate SKU: " + id);
    ids.add(id.toLowerCase());
    const barcode = String(product.barcode ?? "").trim();
    if (barcode) {
      if (barcodes.has(barcode)) throw new TypeError("Duplicate barcode: " + barcode);
      barcodes.add(barcode);
    }
    const r = product.reorderPoint;
    if (r != null && (typeof r !== "number" || !Number.isFinite(r) || r < 0 ||
        Math.abs(r * 1000 - Math.round(r * 1000)) > 1e-7)) {
      throw new TypeError("Reorder threshold must be nonnegative with at most three decimals.");
    }
    if (ledger && (!ledger.products[id] || ledger.products[id].unit !== unit || ledger.products[id].name !== name)) {
      throw new TypeError("Catalogue and ledger disagree for SKU: " + id);
    }
  }
  if (ledger && Object.keys(ledger.products).length !== catalogue.length) {
    throw new TypeError("Catalogue is missing a ledger product.");
  }
  return catalogue;
}
export function addProduct(ledger, catalogue, input) {
  const product = {
    id: required(input.id, "SKU"),
    name: required(input.name, "Name"),
    unit: required(input.unit, "Unit"),
    barcode: String(input.barcode ?? "").trim(),
    category: String(input.category ?? "").trim(),
    reorderPoint: input.reorderPoint === "" || input.reorderPoint == null ? null : Number(input.reorderPoint),
  };
  const nextCatalogue = [...catalogue, product];
  validateCatalogue(nextCatalogue);
  const nextLedger = createLedgerState({
    products: nextCatalogue.map(({ id, name, unit }) => ({ id, name, unit })),
    locations: ledger.locations,
    events: ledger.events,
  });
  return { ledger: nextLedger, catalogue: nextCatalogue };
}
export function addLocation(ledger, catalogue, input) {
  const locationId = uniqueText(input, "Location");
  if (ledger.locations.some((id) => id.toLowerCase() === locationId.toLowerCase())) {
    throw new TypeError("Duplicate location: " + locationId);
  }
  const nextLedger = createLedgerState({
    products: catalogue.map(({ id, name, unit }) => ({ id, name, unit })),
    locations: [...ledger.locations, locationId],
    events: ledger.events,
  });
  return { ledger: nextLedger, catalogue };
}
