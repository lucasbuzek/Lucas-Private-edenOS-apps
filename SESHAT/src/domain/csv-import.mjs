import { addProduct } from "./catalogue.mjs";

export function parseCSV(csv) {
  if (typeof csv !== "string" || csv.length > 1024 * 1024) throw new TypeError("CSV must be text smaller than 1 MB.");
  const rows = [];
  let row = [], field = "", quoted = false, closed = false;
  const input = csv.replace(/^\uFEFF/, "");
  for (let i = 0; i < input.length; i++) {
    const c = input[i];
    if (quoted) {
      if (c === '"' && input[i + 1] === '"') { field += '"'; i++; }
      else if (c === '"') { quoted = false; closed = true; }
      else field += c;
    } else if (c === '"' && !field && !closed) { quoted = true; }
    else if (c === ",") { row.push(field); field = ""; closed = false; }
    else if (c === "\n" || c === "\r") {
      if (c === "\r" && input[i + 1] === "\n") i++;
      row.push(field); if (row.some(x => x.trim())) rows.push(row);
      row = []; field = ""; closed = false;
    } else if (closed || c === '"') { throw new TypeError("Malformed CSV quoting near character " + (i + 1) + "."); }
    else field += c;
  }
  if (quoted) throw new TypeError("CSV has an unterminated quoted field.");
  row.push(field);
  if (row.some(x => x.trim())) rows.push(row);
  return rows;
}

export function previewCatalogueCSV(currentCatalogue, csv) {
  const lines = parseCSV(csv);
  if (!lines.length) throw new TypeError("CSV is empty.");
  if (lines.length > 1001) throw new TypeError("CSV supports at most 1,000 product rows per import.");
  const headers = lines[0].map(h => h.trim());
  if (new Set(headers).size !== headers.length) throw new TypeError("Duplicate CSV headers.");
  for (const name of ["sku","name","unit"]) if (!headers.includes(name)) throw new TypeError("Missing CSV column: " + name + ".");
  const valid = new Set(["sku","name","unit","barcode","category","reorderPoint"]);
  for (const name of headers) if (!valid.has(name)) throw new TypeError("Unsupported CSV column: " + name + ".");
  const products = [], errors = [];
  for (let i = 1; i < lines.length; i++) {
    const values = lines[i], line = i + 1;
    if (values.length !== headers.length) { errors.push({ line, message: "Column count differs from header." }); continue; }
    const d = Object.fromEntries(headers.map((key, idx) => [key, values[idx].trim()]));
    const r = d.reorderPoint;
    const product = { id: d.sku, name: d.name, unit: d.unit,
      barcode: d.barcode || "", category: d.category || "",
      reorderPoint: r == null || r === "" ? null : Number(r) };
    try {
      const check = [...currentCatalogue, ...products];
      // Validate via the canonical catalogue rules without posting stock movements.
      addProduct({products:Object.fromEntries(check.map(p => [p.id,p])),locations:[],events:[]}, check, product);
      products.push(product);
    } catch (error) { errors.push({ line, message: error.message }); }
  }
  return { products, errors, rows: lines.length - 1, canCommit: !errors.length && products.length > 0 };
}
export function applyCatalogueCSV(ledger, catalogue, preview) {
  if (!preview || !preview.canCommit || preview.errors.length || !preview.products.length) {
    throw new TypeError("Import must pass a complete dry-run before commit.");
  }
  let nextLedger = ledger, nextCatalogue = catalogue;
  for (const product of preview.products) {
    const next = addProduct(nextLedger, nextCatalogue, product);
    nextLedger = next.ledger;
    nextCatalogue = next.catalogue;
  }
  return { ledger: nextLedger, catalogue: nextCatalogue };
}
