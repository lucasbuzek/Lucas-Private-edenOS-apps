import { createLedgerState, postMovement } from "../domain/ledger.mjs";

const SCHEMA_VERSION = 1;

function stableStringify(value) {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(",")}]`;
  return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`).join(",")}}`;
}

async function sha256Hex(value) {
  if (!globalThis.crypto?.subtle || typeof TextEncoder === "undefined") {
    throw new Error("Web Crypto SHA-256 is unavailable in this environment.");
  }
  const bytes = new TextEncoder().encode(value);
  const digest = await globalThis.crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function payloadFromState(state) {
  const products = Object.values(state.products)
    .map(({ id, name, unit }) => ({ id, name, unit }))
    .sort((a, b) => a.id.localeCompare(b.id));
  return {
    schemaVersion: SCHEMA_VERSION,
    products,
    locations: [...state.locations].sort(),
    events: state.events.map((event) => ({ ...event })),
  };
}

function exactKeys(value, expected, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new TypeError(`${label} must be an object.`);
  const actual = Object.keys(value).sort();
  const wanted = [...expected].sort();
  if (stableStringify(actual) !== stableStringify(wanted)) throw new TypeError(`${label} has missing or unsupported fields.`);
}

export async function exportLedgerSnapshot(state) {
  const payload = payloadFromState(state);
  const checksum = await sha256Hex(stableStringify(payload));
  return JSON.stringify({ ...payload, checksum: { algorithm: "SHA-256", value: checksum } }, null, 2) + "\n";
}

export async function importLedgerSnapshot(serialized) {
  if (typeof serialized !== "string") throw new TypeError("Snapshot must be JSON text.");
  let document;
  try {
    document = JSON.parse(serialized);
  } catch {
    throw new TypeError("Snapshot is not valid JSON.");
  }
  exactKeys(document, ["schemaVersion", "products", "locations", "events", "checksum"], "Snapshot");
  if (document.schemaVersion !== SCHEMA_VERSION) throw new TypeError(`Unsupported snapshot schema version: ${document.schemaVersion}.`);
  if (!Array.isArray(document.products) || !Array.isArray(document.locations) || !Array.isArray(document.events)) {
    throw new TypeError("Snapshot products, locations and events must be arrays.");
  }
  exactKeys(document.checksum, ["algorithm", "value"], "checksum");
  if (document.checksum.algorithm !== "SHA-256" || typeof document.checksum.value !== "string") {
    throw new TypeError("Snapshot checksum metadata is invalid.");
  }

  const payload = {
    schemaVersion: document.schemaVersion,
    products: document.products,
    locations: document.locations,
    events: document.events,
  };
  const actualChecksum = await sha256Hex(stableStringify(payload));
  if (actualChecksum !== document.checksum.value) throw new TypeError("Snapshot checksum mismatch; content may be corrupted.");

  for (const product of document.products) {
    exactKeys(product, ["id", "name", "unit"], "product");
  }
  for (const [index, event] of document.events.entries()) {
    if (!event || typeof event !== "object" || Array.isArray(event)) throw new TypeError(`Event ${index} must be an object.`);
  }
  if (document.locations.some((location) => typeof location !== "string")) {
    throw new TypeError("Snapshot locations must be strings.");
  }

  let state = createLedgerState({ products: document.products, locations: document.locations });
  for (const [index, rawEvent] of document.events.entries()) {
    const result = postMovement(state, rawEvent);
    if (!result.posted) throw new TypeError(`Snapshot contains a duplicate event at index ${index}.`);
    if (stableStringify(result.event) !== stableStringify(rawEvent)) {
      throw new TypeError(`Event ${index} is not in canonical ledger format.`);
    }
    state = result.state;
  }
  return state;
}