// SESHAT single-device IndexedDB repository.
// A profile revision is checked and written inside one readwrite transaction.
// This is NOT a cross-device or server-authoritative transaction service.
const NAME = "seshat-inventory-local";
const VERSION = 1;
function settle(req) {
  return new Promise((resolve, reject) => { req.onsuccess = () => resolve(req.result); req.onerror = () => reject(req.error); });
}
export function openInventoryDB(indexedDB = globalThis.indexedDB) {
  if (!indexedDB) return Promise.reject(new Error("IndexedDB unavailable: local storage cannot be opened."));
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(NAME, VERSION);
    request.onupgradeneeded = () => {
      if (!request.result.objectStoreNames.contains("profiles")) request.result.createObjectStore("profiles", { keyPath: "key" });
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
    request.onblocked = () => reject(new Error("Close other SESHAT tabs to upgrade local storage."));
  });
}
export async function readInventory(db) {
  const tx = db.transaction("profiles", "readonly");
  const record = await settle(tx.objectStore("profiles").get("current"));
  return record ?? null;
}
export function saveInventory(db, record, expectedRevision) {
  if (!record || typeof record.snapshot !== "string" || !Array.isArray(record.catalogue)) {
    return Promise.reject(new TypeError("Inventory record is invalid."));
  }
  if (!Number.isSafeInteger(expectedRevision) || expectedRevision < 0) {
    return Promise.reject(new TypeError("Expected revision must be a nonnegative integer."));
  }
  return new Promise((resolve, reject) => {
    const tx = db.transaction("profiles", "readwrite");
    let nextRevision = null;
    let error = null;
    const fail = (reason) => { error = reason; try { tx.abort(); } catch {} };
    tx.onerror = () => { error ??= tx.error; };
    tx.onabort = () => reject(error ?? tx.error ?? new Error("Local save aborted."));
    tx.oncomplete = () => resolve(nextRevision);
    const store = tx.objectStore("profiles");
    const read = store.get("current");
    read.onerror = () => fail(read.error);
    read.onsuccess = () => {
      const actual = read.result?.revision ?? 0;
      if (actual !== expectedRevision) {
        fail(new Error("CONFLICT: inventory changed in another tab. Reload before posting."));
        return;
      }
      nextRevision = actual + 1;
      store.put({
        key: "current", revision: nextRevision, snapshot: record.snapshot,
        catalogue: record.catalogue, provenance: record.provenance ?? "local",
        savedAt: new Date().toISOString(),
      });
    };
  });
}
