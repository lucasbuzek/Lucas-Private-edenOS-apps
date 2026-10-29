import { getStockSummary, getOnHand } from "./ledger.mjs";

function normalize(value) {
  return String(value ?? "").trim().toLocaleLowerCase("en");
}

function requireProvenance(provenance) {
  if (!provenance || typeof provenance.label !== "string" || !provenance.label.trim()) {
    throw new TypeError("A named data provenance is required.");
  }
  return {
    label: provenance.label.trim(),
    kind: provenance.kind ?? "unknown",
    asOf: provenance.asOf ?? null,
  };
}

export function searchProducts(catalogue, query) {
  const term = normalize(query);
  if (!term) throw new TypeError("Enter a product name, SKU or barcode.");
  return catalogue.filter((product) =>
    [product.id, product.name, product.barcode, product.category]
      .some((field) => normalize(field).includes(term))
  ).map((product) => ({ ...product }));
}

/**
 * Read-only assistant query surface. It never posts ledger events or writes to providers.
 * Inventory availability remains UNKNOWN until reservation/incoming workflows are implemented.
 */
export function answerInventoryQuery({ state, catalogue, provenance, intent, query = "", locationId = null }) {
  const source = requireProvenance(provenance);
  const products = Array.isArray(catalogue) ? catalogue : [];
  const answerBase = { source, readOnly: true, externalWrites: "DISABLED" };

  if (intent === "search") {
    return { ...answerBase, intent, matches: searchProducts(products, query) };
  }

  if (intent === "stock" || intent === "movement-history") {
    const matches = searchProducts(products, query);
    if (matches.length === 0) return { ...answerBase, intent, status: "NOT_FOUND", matches: [] };
    if (matches.length > 1) return { ...answerBase, intent, status: "NEEDS_SELECTION", matches };

    const product = matches[0];
    if (!state.products[product.id]) {
      return { ...answerBase, intent, status: "NO_LEDGER_RECORD", product };
    }
    if (intent === "movement-history") {
      return {
        ...answerBase, intent, status: "OK", product,
        events: state.events.filter((event) => event.productId === product.id).map((event) => ({ ...event })),
      };
    }

    const summary = getStockSummary(state, product.id);
    const onHand = locationId ? getOnHand(state, product.id, locationId) : summary.total;
    const reorderPoint = product.reorderPoint;
    const lowStock = typeof reorderPoint === "number" ? onHand <= reorderPoint : null;
    return {
      ...answerBase, intent, status: "OK", product,
      locationId: locationId ?? "ALL_LOCATIONS",
      onHand, unit: summary.unit, byLocation: summary.byLocation,
      reorderPoint: typeof reorderPoint === "number" ? reorderPoint : null,
      lowStock,
      reserved: { status: "UNKNOWN", reason: "Reservation workflow is not implemented." },
      available: { status: "UNKNOWN", reason: "Reserved quantity is not established." },
      incoming: { status: "UNKNOWN", reason: "Purchase-order receiving workflow is not implemented." },
    };
  }

  if (intent === "low-stock") {
    const rows = [];
    for (const product of products) {
      if (typeof product.reorderPoint !== "number" || !state.products[product.id]) continue;
      const summary = getStockSummary(state, product.id);
      const onHand = locationId ? getOnHand(state, product.id, locationId) : summary.total;
      if (onHand <= product.reorderPoint) {
        rows.push({
          product: { ...product },
          locationId: locationId ?? "ALL_LOCATIONS",
          onHand,
          unit: summary.unit,
          reorderPoint: product.reorderPoint,
          shortage: Math.max(0, product.reorderPoint - onHand),
        });
      }
    }
    return { ...answerBase, intent, status: "OK", items: rows };
  }

  return {
    ...answerBase, intent, status: "UNSUPPORTED_INTENT",
    supportedIntents: ["search", "stock", "low-stock", "movement-history"],
  };
}

