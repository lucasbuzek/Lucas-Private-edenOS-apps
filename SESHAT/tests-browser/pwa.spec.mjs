import { test, expect } from "@playwright/test";

test("local inventory: catalogue, receipt, reload and stock visibility", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByText("Local-only", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Catalogue & locations" }).click();
  await page.getByLabel("Location identifier").fill("shop");
  await page.getByRole("button", { name: "Add location" }).click();
  await expect(page.locator("#location-list")).toContainText("shop");
  await page.getByLabel("SKU", { exact: true }).fill("EGG-001");
  await page.getByLabel("Product name").fill("Eggs");
  await page.getByLabel("Unit").fill("each");
  await page.getByLabel("Reorder threshold").fill("5");
  await page.getByRole("button", { name: "Add product" }).click();
  await page.getByRole("button", { name: "Stock movements" }).click();
  await page.getByLabel("Quantity").fill("12");
  await page.getByRole("button", { name: "Preview movement" }).click();
  await expect(page.locator("#movement-preview")).toContainText("PREVIEW ONLY");
  await expect(page.locator("#history-count")).toContainText("0 ledger entries");
  await page.getByRole("button", { name: "Confirm and post" }).click();
  await page.getByRole("button", { name: "Overview" }).click();
  await expect(page.locator("#overview-body")).toContainText("12 each");
  await page.reload();
  await expect(page.locator("#overview-body")).toContainText("12 each");
  await expect(page.locator("#stat-movements")).toHaveText("1");
});

test("stale second tab cannot overwrite the first tab", async ({ context, page }) => {
  const second = await context.newPage();
  await Promise.all([page.goto("/"), second.goto("/")]);
  await page.getByRole("button", { name: "Catalogue & locations" }).click();
  await second.getByRole("button", { name: "Catalogue & locations" }).click();
  await page.getByLabel("Location identifier").fill("first");
  await page.getByRole("button", { name: "Add location" }).click();
  await second.getByLabel("Location identifier").fill("stale");
  await second.getByRole("button", { name: "Add location" }).click();
  await expect(second.locator("#notice")).toContainText("CONFLICT");
  await second.reload();
  await expect(second.locator("#location-list")).toContainText("first");
  await expect(second.locator("#location-list")).not.toContainText("stale");
});

test("service worker permits offline cold reload after installation", async ({ context, page }) => {
  await page.goto("/");
  await page.evaluate(async () => { await navigator.serviceWorker.ready; });
  await context.setOffline(true);
  await page.reload();
  await expect(page.getByText("Know what is in stock.")).toBeVisible();
  await expect(page.locator("#network-state")).toContainText("Browser offline");
});

test("CSV import requires explicit preview and does not alter stock", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "Backup & restore" }).click();
  await page.locator("#csv-file").setInputFiles({
    name: "catalogue.csv", mimeType: "text/csv",
    buffer: Buffer.from("sku,name,unit,barcode,category,reorderPoint\nEGG-1,Chicken eggs,each,123,Poultry,12\n"),
  });
  await page.getByRole("button", { name: "Preview catalogue import" }).click();
  await expect(page.locator("#csv-preview")).toContainText("1 valid new products");
  await page.getByRole("button", { name: "Overview" }).click();
  await expect(page.locator("#stat-products")).toHaveText("0");
  await page.getByRole("button", { name: "Backup & restore" }).click();
  page.once("dialog", dialog => dialog.accept());
  await page.getByRole("button", { name: "Confirm and import" }).click();
  await page.getByRole("button", { name: "Overview" }).click();
  await expect(page.locator("#overview-body")).toContainText("Chicken eggs");
  await expect(page.locator("#stat-movements")).toHaveText("0");
});
